require 'securerandom'
require 'cadence/testing/local_activity_context'
require 'cadence/testing/workflow_execution'
require 'cadence/execution_options'
require 'cadence/metadata/activity'
require 'cadence/workflow/future'
require 'cadence/workflow/history/event_target'

module Cadence
  module Testing
    class LocalWorkflowContext
      attr_reader :headers

      def initialize(execution, workflow_id, run_id, disabled_releases, headers = {})
        @last_event_id = 0
        @execution = execution
        @run_id = run_id
        @workflow_id = workflow_id
        @disabled_releases = disabled_releases
        @headers = headers
      end

      def logger
        Cadence.logger
      end

      def has_release?(change_name)
        !disabled_releases.include?(change_name.to_s)
      end

      def execute_activity(activity_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        event_id = next_event_id
        activity_id = options[:activity_id] || event_id

        target = Workflow::History::EventTarget.new(event_id, Workflow::History::EventTarget::ACTIVITY_TYPE)
        future = Workflow::Future.new(target, self, cancelation_id: activity_id)

        execution_options = ExecutionOptions.new(activity_class, options)
        metadata = Metadata::Activity.new(
          domain: execution_options.domain,
          id: activity_id,
          name: execution_options.name,
          task_token: nil,
          attempt: 1,
          workflow_run_id: run_id,
          workflow_id: workflow_id,
          workflow_name: nil, # not yet used, but will be in the future
          headers: execution_options.headers
        )
        context = LocalActivityContext.new(metadata)

        result = activity_class.execute_in_context(context, input)

        if context.async?
          execution.register_future(context.async_token, future)
        else
          # Fulfil the future straigt away for non-async activities
          future.set(result)
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

      def execute_local_activity(activity_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        execution_options = ExecutionOptions.new(activity_class, options)
        activity_id = options[:activity_id] || SecureRandom.uuid
        metadata = Metadata::Activity.new(
          domain: execution_options.domain,
          id: activity_id,
          name: execution_options.name,
          task_token: nil,
          attempt: 1,
          workflow_run_id: run_id,
          workflow_id: workflow_id,
          workflow_name: nil, # not yet used, but will be in the future
          headers: execution_options.headers
        )
        context = LocalActivityContext.new(metadata)

        activity_class.execute_in_context(context, input)
      end

      def execute_workflow(workflow_class, *input, **args)
        raise NotImplementedError, 'not yet available for testing'
      end

      def execute_workflow!(workflow_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        execution = WorkflowExecution.new
        workflow_id = SecureRandom.uuid
        run_id = SecureRandom.uuid
        execution_options = ExecutionOptions.new(workflow_class, options)
        context = Cadence::Testing::LocalWorkflowContext.new(
          execution, workflow_id, run_id, workflow_class.disabled_releases, execution_options.headers
        )

        workflow_class.execute_in_context(context, input)
      end

      def side_effect(&block)
        block.call
      end

      def sleep(timeout)
        ::Kernel.sleep timeout
      end

      def start_timer(timeout, timer_id = nil)
        raise NotImplementedError, 'not yet available for testing'
      end

      def cancel_timer(timer_id)
        raise NotImplementedError, 'not yet available for testing'
      end

      def complete(result = nil)
        result
      end

      def fail(reason, details = nil)
        error_class = safe_constantize(reason) || StandardError

        raise error_class, details
      end

      def wait_for_all(*futures)
        futures.each(&:wait)

        return
      end

      def wait_for(future)
        # Point of communication
        Fiber.yield while !future.finished?
      end

      def now
        Time.now
      end

      def on_signal(&block)
        raise NotImplementedError, 'not yet available for testing'
      end

      def cancel_activity(activity_id)
        raise NotImplementedError, 'not yet available for testing'
      end

      def cancel(target, cancelation_id)
        raise NotImplementedError, 'not yet available for testing'
      end

      private

      attr_reader :execution, :run_id, :workflow_id, :disabled_releases

      def next_event_id
        @last_event_id += 1
        @last_event_id
      end

      def safe_constantize(const)
        Object.const_get(const) if Object.const_defined?(const)
      rescue NameError
        nil
      end
    end
  end
end
