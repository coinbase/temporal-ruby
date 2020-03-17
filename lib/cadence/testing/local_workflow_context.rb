require 'securerandom'
require 'cadence/testing/local_activity_context'

module Cadence
  module Testing
    class LocalWorkflowContext
      def initialize(workflow_id = nil)
        @run_id = SecureRandom.uuid
        @workflow_id = workflow_id || SecureRandom.uuid
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

        context = LocalActivityContext.new(run_id, workflow_id)
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
