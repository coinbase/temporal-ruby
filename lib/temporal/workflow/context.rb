require 'securerandom'

require 'temporal/execution_options'
require 'temporal/errors'
require 'temporal/thread_local_context'
require 'temporal/workflow/history/event_target'
require 'temporal/workflow/command'
require 'temporal/workflow/context_helpers'
require 'temporal/workflow/future'
require 'temporal/workflow/child_workflow_future'
require 'temporal/workflow/replay_aware_logger'
require 'temporal/workflow/stack_trace_tracker'
require 'temporal/workflow/state_manager'
require 'temporal/workflow/signal'

# This context class is available in the workflow implementation
# and provides context and methods for interacting with Temporal
#
module Temporal
  class Workflow
    class Context
      attr_reader :metadata, :config

      def initialize(state_manager, dispatcher, workflow_class, metadata, config, query_registry, track_stack_trace)
        @state_manager = state_manager
        @dispatcher = dispatcher
        @query_registry = query_registry
        @workflow_class = workflow_class
        @metadata = metadata
        @completed = false
        @config = config

        if track_stack_trace
          @stack_trace_tracker = StackTraceTracker.new
        else
          @stack_trace_tracker = nil
        end

        query_registry.register(StackTraceTracker::STACK_TRACE_QUERY_NAME) do
          stack_trace_tracker&.to_s
        end
      end

      def completed?
        @completed
      end

      def logger
        @logger ||= ReplayAwareLogger.new(Temporal.logger)
        @logger.replay = state_manager.replay?
        @logger
      end

      def headers
        metadata.headers
      end

      def has_release?(release_name)
        state_manager.release?(release_name.to_s)
      end

      def execute_activity(activity_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        execution_options = ExecutionOptions.new(activity_class, options, config.default_execution_options)

        command = Command::ScheduleActivity.new(
          activity_id: options[:activity_id],
          activity_type: execution_options.name,
          input: input,
          namespace: execution_options.namespace,
          task_queue: execution_options.task_queue,
          retry_policy: execution_options.retry_policy,
          timeouts: execution_options.timeouts,
          headers: execution_options.headers
        )

        target, cancelation_id = schedule_command(command)
        future = Future.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'completed') do |result|
          future.set(result)
          future.success_callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'failed') do |exception|
          future.fail(exception)
          future.failure_callbacks.each { |callback| call_in_fiber(callback, exception) }
        end

        future
      end

      def execute_activity!(activity_class, *input, **args)
        future = execute_activity(activity_class, *input, **args)
        result = future.get

        raise result if future.failed?

        result
      end

      # TODO: how to handle failures?
      def execute_local_activity(activity_class, *input, **args)
        input << args unless args.empty?

        side_effect do
          # TODO: this probably requires a local context implementation
          context = Activity::Context.new(nil, nil)
          activity_class.execute_in_context(context, input)
        end
      end

      def execute_workflow(workflow_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        parent_close_policy = options.delete(:parent_close_policy)
        cron_schedule = options.delete(:cron_schedule)
        workflow_id_reuse_policy = options.delete(:workflow_id_reuse_policy)
        execution_options = ExecutionOptions.new(workflow_class, options, config.default_execution_options)

        command = Command::StartChildWorkflow.new(
          workflow_id: options[:workflow_id] || SecureRandom.uuid,
          workflow_type: execution_options.name,
          input: input,
          namespace: execution_options.namespace,
          task_queue: execution_options.task_queue,
          retry_policy: execution_options.retry_policy,
          parent_close_policy: parent_close_policy,
          timeouts: execution_options.timeouts,
          headers: execution_options.headers,
          cron_schedule: cron_schedule,
          memo: execution_options.memo,
          workflow_id_reuse_policy: workflow_id_reuse_policy || execution_options.workflow_id_reuse_policy,
          search_attributes: Helpers.process_search_attributes(execution_options.search_attributes),
        )

        target, cancelation_id = schedule_command(command)

        child_workflow_future = ChildWorkflowFuture.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'completed') do |result|
          child_workflow_future.set(result)
          child_workflow_future.success_callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'failed') do |exception|
          # if the child workflow didn't start already then also fail that future
          unless child_workflow_future.child_workflow_execution_future.ready?
            child_workflow_future.child_workflow_execution_future.fail(exception)
            child_workflow_future.child_workflow_execution_future.failure_callbacks.each { |callback| call_in_fiber(callback, exception) }
          end

          child_workflow_future.fail(exception)
          child_workflow_future.failure_callbacks.each { |callback| call_in_fiber(callback, exception) }
        end

        dispatcher.register_handler(target, 'started') do |event|
          # once the workflow starts, complete the child workflow execution future
          child_workflow_future.child_workflow_execution_future.set(event)
          child_workflow_future.child_workflow_execution_future.success_callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        child_workflow_future
      end

      def execute_workflow!(workflow_class, *input, **args)
        future = execute_workflow(workflow_class, *input, **args)
        result = future.get

        raise result if future.failed?

        result
      end

      def schedule_workflow(workflow_class, cron_schedule, *input, **args)
        args[:options] = (args[:options] || {}).merge(cron_schedule: cron_schedule)
        execute_workflow(workflow_class, *input, **args)
      end

      def side_effect(&block)
        marker = state_manager.next_side_effect
        return marker.last if marker

        result = block.call
        command = Command::RecordMarker.new(name: StateManager::SIDE_EFFECT_MARKER, details: result)
        schedule_command(command)

        result
      end

      def sleep(timeout)
        start_timer(timeout).wait
      end

      def start_timer(timeout, timer_id = nil)
        command = Command::StartTimer.new(timeout: timeout, timer_id: timer_id)
        target, cancelation_id = schedule_command(command)
        future = Future.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'fired') do |result|
          future.set(result)
          future.success_callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'canceled') do |exception|
          future.fail(exception)
          future.failure_callbacks.each { |callback| call_in_fiber(callback, exception) }
        end

        future
      end

      def cancel_timer(timer_id)
        command = Command::CancelTimer.new(timer_id: timer_id)
        schedule_command(command)
      end

      # TODO: check if workflow can be completed
      def complete(result = nil)
        command = Command::CompleteWorkflow.new(result: result)
        schedule_command(command)
        completed!
      end

      # TODO: check if workflow can be failed
      def fail(exception)
        command = Command::FailWorkflow.new(exception: exception)
        schedule_command(command)
        completed!
      end

      def continue_as_new(*input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        # If memo or headers are not overridden, use those from the current run
        options_from_metadata = {
          memo: metadata.memo,
          headers: metadata.headers,
        }
        options = options_from_metadata.merge(options)

        execution_options = ExecutionOptions.new(workflow_class, options, config.default_execution_options)

        command = Command::ContinueAsNew.new(
          workflow_type: execution_options.name,
          task_queue: execution_options.task_queue,
          input: input,
          timeouts: execution_options.timeouts,
          retry_policy: execution_options.retry_policy,
          headers: execution_options.headers,
          memo: execution_options.memo,
          search_attributes: Helpers.process_search_attributes(execution_options.search_attributes),
        )
        schedule_command(command)
        completed!
      end

      # Block workflow progress until all futures finish
      def wait_for_all(*futures)
        futures.each(&:wait)

        return
      end

      # Block workflow progress until one of the futures completes. Passing
      # in an empty array will immediately unblock.
      def wait_for_any(*futures)
        return if futures.empty? || futures.any?(&:finished?)

        fiber = Fiber.current

        handlers = futures.map do |future|
          dispatcher.register_handler(future.target, Dispatcher::WILDCARD) do
            fiber.resume if future.finished?
          end
        end

        stack_trace_tracker&.record
        begin
          Fiber.yield
        ensure
          stack_trace_tracker&.clear
          handlers.each(&:unregister)
        end

        return
      end

      # Block workflow progress until the specified block evaluates to true.
      def wait_until(&unblock_condition)
        raise 'You must pass a block to wait_until' if unblock_condition.nil?

        return if unblock_condition.call

        fiber = Fiber.current

        # wait_until condition blocks often read state modified by target-specfic handlers like
        # signal handlers or callbacks for timer or activity completion. Running the wait_until
        # handlers after the other handlers ensures that state is correctly updated before being
        # read.
        handler = dispatcher.register_handler(
          Dispatcher::WILDCARD, # any target
          Dispatcher::WILDCARD, # any event type
          Dispatcher::Order::AT_END) do
          fiber.resume if unblock_condition.call
        end

        stack_trace_tracker&.record
        begin
          Fiber.yield
        ensure
          stack_trace_tracker&.clear
          handler.unregister
        end

        return
      end

      def now
        state_manager.local_time
      end

      # Define a signal handler to receive signals onto the workflow. When
      # +name+ is defined, this creates a named signal handler which will be
      # invoked whenever a signal named +name+ is received. A handler without
      # a set name (defaults to nil) will be the default handler and will receive
      # all signals that do not match a named signal handler.
      #
      # @param signal_name [String, Symbol, nil] an optional signal name; converted to a String
      def on_signal(signal_name = nil, &block)
        if signal_name
          target = Signal.new(signal_name)
          dispatcher.register_handler(target, 'signaled') do |_, input|
            # do not pass signal name when triggering a named handler
            call_in_fiber(block, input)
          end
        else
          dispatcher.register_handler(Dispatcher::WILDCARD, 'signaled') do |signal, input|
            call_in_fiber(block, signal, input)
          end
        end

        return
      end

      def on_query(query, &block)
        query_registry.register(query, &block)
      end

      def cancel_activity(activity_id)
        command = Command::RequestActivityCancellation.new(activity_id: activity_id)

        schedule_command(command)
      end

      def cancel(target, cancelation_id)
        case target.type
        when History::EventTarget::ACTIVITY_TYPE
          cancel_activity(cancelation_id)
        when History::EventTarget::TIMER_TYPE
          cancel_timer(cancelation_id)
        else
          raise "#{target} can not be canceled"
        end
      end

      # Send a signal from inside a workflow to another workflow. Not to be confused with
      # Client#signal_workflow which sends a signal from outside a workflow to a workflow.
      #
      # @param workflow [Temporal::Workflow, nil] workflow class or nil
      # @param signal [String] name of the signal to send
      # @param workflow_id [String]
      # @param run_id [String]
      # @param input [String, Array, nil] optional arguments for the signal
      # @param namespace [String, nil] if nil, choose the one declared on the workflow class or the
      #   global default
      # @param child_workflow_only [Boolean] indicates whether the signal should only be delivered to a
      # child workflow; defaults to false
      #
      # @return [Future] future
      def signal_external_workflow(workflow, signal, workflow_id, run_id = nil, input = nil, namespace: nil, child_workflow_only: false)
        execution_options = ExecutionOptions.new(workflow, {}, config.default_execution_options)

        command = Command::SignalExternalWorkflow.new(
          namespace: namespace || execution_options.namespace,
          execution: {
            workflow_id: workflow_id,
            run_id: run_id
          },
          signal_name: signal,
          input: input,
          child_workflow_only: child_workflow_only
        )

        target, cancelation_id = schedule_command(command)
        future = Future.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'completed') do |result|
          future.set(result)
          future.success_callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'failed') do |exception|
          future.fail(exception)
          future.failure_callbacks.each { |callback| call_in_fiber(callback, exception) }
        end

        future
      end

      # Replaces or adds the values of your custom search attributes specified during a workflow's execution.
      # To use this your server must support Elasticsearch, and the attributes must be pre-configured
      # See https://docs.temporal.io/docs/concepts/what-is-a-search-attribute/
      #
      # @param search_attributes [Hash]
      #   If an attribute is registered as a Datetime, you can pass in a Time: e.g.
      #     workflow.now
      #   or as a string in UTC ISO-8601 format:
      #     workflow.now.utc.iso8601
      #   It would look like: "2022-03-01T17:39:06Z"
      # @return [Hash] the search attributes after any preprocessing.
      #
      def upsert_search_attributes(search_attributes)
        search_attributes = Helpers.process_search_attributes(search_attributes)
        if search_attributes.empty?
          raise ArgumentError, "Cannot upsert an empty hash for search_attributes, as this would do nothing."
        end
        command = Command::UpsertSearchAttributes.new(
          search_attributes: search_attributes
        )
        schedule_command(command)
        search_attributes
      end

      private

      attr_reader :state_manager, :dispatcher, :workflow_class, :query_registry, :stack_trace_tracker

      def completed!
        @completed = true
      end

      def schedule_command(command)
        state_manager.schedule(command)
      end

      def call_in_fiber(block, *args)
        Fiber.new do
          Temporal::ThreadLocalContext.set(self)
          block.call(*args)
        end.resume
      end
    end
  end
end
