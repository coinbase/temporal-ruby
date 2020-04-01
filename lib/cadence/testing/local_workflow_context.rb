require 'securerandom'
require 'cadence/testing/local_activity_context'
require 'cadence/execution_options'

module Cadence
  module Testing
    class LocalWorkflowContext
      attr_reader :headers

      def initialize(workflow_id = nil, headers = {})
        @run_id = SecureRandom.uuid
        @workflow_id = workflow_id || SecureRandom.uuid
        @headers = headers
      end

      def logger
        Cadence.logger
      end

      def execute_activity(activity_class, *input, **args)
        raise NotImplementedError, 'not yet available for testing'
      end

      def execute_activity!(activity_class, *input, **args)
        execute_local_activity(activity_class, *input, **args)
      end

      def execute_local_activity(activity_class, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        execution_options = ExecutionOptions.new(activity_class, options)
        context = LocalActivityContext.new(run_id, workflow_id, execution_options.headers)

        activity_class.execute_in_context(context, input)
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
        result # return the result
      end

      def fail(reason, details = nil)
        p reason
        p details

        raise reason
      end

      def wait_for_all(*futures)
        raise NotImplementedError, 'not yet available for testing'
      end

      def wait_for(future)
        raise NotImplementedError, 'not yet available for testing'
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

      attr_reader :run_id, :workflow_id
    end
  end
end
