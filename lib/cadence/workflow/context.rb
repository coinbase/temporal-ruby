require 'securerandom'

require 'cadence/execution_options'
require 'cadence/errors'
require 'cadence/thread_local_context'
require 'cadence/workflow/history/event_target'
require 'cadence/workflow/decision'
require 'cadence/workflow/future'
require 'cadence/workflow/replay_aware_logger'

# This context class is available in the workflow implementation
# and provides context and methods for interacting with Cadence
#
module Cadence
  class Workflow
    class Context
      def initialize(state_manager, dispatcher, metadata)
        @state_manager = state_manager
        @dispatcher = dispatcher
        @metadata = metadata
      end

      def logger
        @logger ||= ReplayAwareLogger.new(Cadence.logger)
        @logger.replay = state_manager.replay?
        @logger
      end

      def headers
        metadata.headers
      end

      def execute_activity(activity_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        execution_options = ExecutionOptions.new(activity_class, options)

        decision = Decision::ScheduleActivity.new(
          activity_id: options[:activity_id],
          activity_type: execution_options.name,
          input: input,
          domain: execution_options.domain,
          task_list: execution_options.task_list,
          retry_policy: execution_options.retry_policy,
          timeouts: execution_options.timeouts,
          headers: execution_options.headers
        )

        target, cancelation_id = schedule_decision(decision)
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

          error_class = safe_constantize(reason) || Cadence::ActivityException

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

        decision = Decision::StartChildWorkflow.new(
          workflow_id: options[:workflow_id] || SecureRandom.uuid,
          workflow_type: execution_options.name,
          input: input,
          domain: execution_options.domain,
          task_list: execution_options.task_list,
          retry_policy: execution_options.retry_policy,
          timeouts: execution_options.timeouts,
          headers: execution_options.headers
        )

        target, cancelation_id = schedule_decision(decision)
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
        future = execute_worfklow(workflow_class, *input, **args)
        result = future.get

        if future.failed?
          reason, details = result

          error_class = safe_constantize(reason) || StandardError.new(details)

          raise error_class, details
        end

        result
      end

      def side_effect(&block)
        marker = state_manager.check_next_marker
        result = marker ? marker.last : block.call

        decision = Decision::RecordMarker.new(name: 'SIDE_EFFECT', details: result)
        schedule_decision(decision)

        result
      end

      def sleep(timeout)
        start_timer(timeout).wait
      end

      def start_timer(timeout, timer_id = nil)
        timer_id ||= SecureRandom.uuid
        decision = Decision::StartTimer.new(timeout: timeout, timer_id: timer_id)
        target, cancelation_id = schedule_decision(decision)
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
        decision = Decision::CancelTimer.new(timer_id: timer_id)
        schedule_decision(decision)
      end

      # TODO: check if workflow can be completed
      def complete(result = nil)
        decision = Decision::CompleteWorkflow.new(result: result)
        schedule_decision(decision)
      end

      # TODO: check if workflow can be failed
      def fail(reason, details = nil)
        decision = Decision::FailWorkflow.new(reason: reason, details: details)
        schedule_decision(decision)
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
        decision = Decision::RequestActivityCancellation.new(activity_id: activity_id)

        schedule_decision(decision)
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

      def schedule_decision(decision)
        state_manager.schedule(decision)
      end

      def call_in_fiber(block, *args)
        Fiber.new do
          Cadence::ThreadLocalContext.set(self)
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
