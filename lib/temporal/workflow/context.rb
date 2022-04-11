require 'securerandom'

require 'temporal/execution_options'
require 'temporal/errors'
require 'temporal/thread_local_context'
require 'temporal/workflow/history/event_target'
require 'temporal/workflow/command'
require 'temporal/workflow/context_helpers'
require 'temporal/workflow/future'
require 'temporal/workflow/replay_aware_logger'
require 'temporal/workflow/state_manager'

# This context class is available in the workflow implementation
# and provides context and methods for interacting with Temporal
#
module Temporal
  class Workflow
    class Context
      attr_reader :metadata, :config

      def initialize(state_manager, dispatcher, workflow_class, metadata, config, query_registry)
        @state_manager = state_manager
        @dispatcher = dispatcher
        @query_registry = query_registry
        @workflow_class = workflow_class
        @metadata = metadata
        @completed = false
        @config = config
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
          memo: execution_options.memo,
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

        # Temporal docs say that we *must* wait for the child to get spawned:
        child_workflow_started = false
        dispatcher.register_handler(target, 'started') do
          child_workflow_started = true
        end
        wait_for { child_workflow_started }

        future
      end

      def execute_workflow!(workflow_class, *input, **args)
        future = execute_workflow(workflow_class, *input, **args)
        result = future.get

        raise result if future.failed?

        result
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
        )
        schedule_command(command)
        completed!
      end

      def wait_for_all(*futures)
        futures.each(&:wait)

        return
      end

      # Block workflow progress until any future is finished or any unblock_condition
      # block evaluates to true.
      def wait_for(*futures, &unblock_condition)
        if futures.empty? && unblock_condition.nil?
          raise 'You must pass either a future or an unblock condition block to wait_for'
        end

        fiber = Fiber.current
        should_yield = false
        blocked = true

        if futures.any?
          if futures.any?(&:finished?)
            blocked = false
          else
            should_yield = true
            futures.each do |future|
              dispatcher.register_handler(future.target, Dispatcher::WILDCARD) do
                if blocked && future.finished?
                  # Because this block can run for any dispatch, ensure the fiber is only
                  # resumed one time by checking if it's already been unblocked.
                  blocked = false
                  fiber.resume
                end
              end
            end
          end
        end

        if blocked && unblock_condition
          if unblock_condition.call
            blocked = false
            should_yield = false
          else
            should_yield = true

            dispatcher.register_handler(Dispatcher::TARGET_WILDCARD, Dispatcher::WILDCARD) do
              # Because this block can run for any dispatch, ensure the fiber is only
              # resumed one time by checking if it's already been unblocked.
              if blocked && unblock_condition.call
                blocked = false
                fiber.resume
              end
            end
          end
        end

        Fiber.yield if should_yield

        return
      end

      def now
        state_manager.local_time
      end

      def on_signal(&block)
        target = History::EventTarget.workflow

        dispatcher.register_handler(target, 'signaled') do |signal, input|
          call_in_fiber(block, signal, input)
        end
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
        command = Command::UpsertSearchAttributes.new(
          search_attributes: search_attributes
        )
        schedule_command(command)
        search_attributes
      end

      private

      attr_reader :state_manager, :dispatcher, :workflow_class, :query_registry

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
