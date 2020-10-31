require 'securerandom'

require 'temporal/execution_options'
require 'temporal/errors'
require 'temporal/thread_local_context'
require 'temporal/workflow/history/event_target'
require 'temporal/workflow/future'
require 'temporal/workflow/replay_aware_logger'
require 'temporal/workflow/state_manager'
require 'temporal/workflow/workflow_task'

# This context class is available in the workflow implementation
# and provides context and methods for interacting with Temporal
#
module Temporal
  class Workflow
    class Context
      def initialize(state_manager, dispatcher, metadata)
        @state_manager = state_manager
        @dispatcher = dispatcher
        @metadata = metadata
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

        execution_options = ExecutionOptions.new(activity_class, options)

        workflow_task = WorkflowTask::ScheduleActivity.new(
          activity_id: options[:activity_id],
          activity_type: execution_options.name,
          input: input,
          namespace: execution_options.namespace,
          task_queue: execution_options.task_queue,
          retry_policy: execution_options.retry_policy,
          timeouts: execution_options.timeouts,
          headers: execution_options.headers
        )

        target, cancelation_id = schedule_workflow_task(workflow_task)
        future = Future.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'completed') do |result|
          future.set(result)
          future.callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'failed') do |reason, details|
          future.fail(reason, details)
        end

        future
      end

      def execute_activity!(activity_class, *input, **args)
        future = execute_activity(activity_class, *input, **args)
        result = future.get

        if future.failed?
          reason, details = result

          error_class = safe_constantize(reason) || Temporal::ActivityException

          raise error_class, details
        end

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

        execution_options = ExecutionOptions.new(workflow_class, options)

        workflow_task = WorkflowTask::StartChildWorkflow.new(
          workflow_id: options[:workflow_id] || SecureRandom.uuid,
          workflow_type: execution_options.name,
          input: input,
          namespace: execution_options.namespace,
          task_queue: execution_options.task_queue,
          retry_policy: execution_options.retry_policy,
          timeouts: execution_options.timeouts,
          headers: execution_options.headers
        )

        target, cancelation_id = schedule_workflow_task(workflow_task)
        future = Future.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'completed') do |result|
          future.set(result)
          future.callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'failed') do |reason, details|
          future.fail(reason, details)
        end

        future
      end

      def execute_workflow!(workflow_class, *input, **args)
        future = execute_workflow(workflow_class, *input, **args)
        result = future.get

        if future.failed?
          reason, details = result

          error_class = safe_constantize(reason) || StandardError.new(details)

          raise error_class, details
        end

        result
      end

      def side_effect(&block)
        marker = state_manager.next_side_effect
        return marker.last if marker

        result = block.call
        workflow_task = WorkflowTask::RecordMarker.new(name: StateManager::SIDE_EFFECT_MARKER, details: result)
        schedule_workflow_task(workflow_task)

        result
      end

      def sleep(timeout)
        start_timer(timeout).wait
      end

      def start_timer(timeout, timer_id = nil)
        workflow_task = WorkflowTask::StartTimer.new(timeout: timeout, timer_id: timer_id)
        target, cancelation_id = schedule_workflow_task(workflow_task)
        future = Future.new(target, self, cancelation_id: cancelation_id)

        dispatcher.register_handler(target, 'fired') do |result|
          future.set(result)
          future.callbacks.each { |callback| call_in_fiber(callback, result) }
        end

        dispatcher.register_handler(target, 'canceled') do |reason, details|
          future.fail(reason, details)
        end

        future
      end

      def cancel_timer(timer_id)
        workflow_task = WorkflowTask::CancelTimer.new(timer_id: timer_id)
        schedule_workflow_task(workflow_task)
      end

      # TODO: check if workflow can be completed
      def complete(result = nil)
        workflow_task = WorkflowTask::CompleteWorkflow.new(result: result)
        schedule_workflow_task(workflow_task)
      end

      # TODO: check if workflow can be failed
      def fail(reason, details = nil)
        workflow_task = WorkflowTask::FailWorkflow.new(reason: reason, details: details)
        schedule_workflow_task(workflow_task)
      end

      def wait_for_all(*futures)
        futures.each(&:wait)

        return
      end

      def wait_for(future)
        fiber = Fiber.current

        dispatcher.register_handler(future.target, Dispatcher::WILDCARD) do
          fiber.resume if future.finished?
        end

        Fiber.yield

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

      def cancel_activity(activity_id)
        workflow_task = WorkflowTask::RequestActivityCancellation.new(activity_id: activity_id)

        schedule_workflow_task(workflow_task)
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

      private

      attr_reader :state_manager, :dispatcher, :metadata

      def schedule_workflow_task(workflow_task)
        state_manager.schedule(workflow_task)
      end

      def call_in_fiber(block, *args)
        Fiber.new do
          Temporal::ThreadLocalContext.set(self)
          block.call(*args)
        end.resume
      end

      def safe_constantize(const)
        Object.const_get(const) if Object.const_defined?(const)
      rescue NameError
        nil
      end
    end
  end
end
