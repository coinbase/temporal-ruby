require 'fiber'

module Temporal
  class Workflow
    class Future
      attr_reader :target, :success_callbacks, :failure_callbacks

      def initialize(target, context, cancelation_id: nil)
        @target = target
        @context = context
        @cancelation_id = cancelation_id
        @success_callbacks = []
        @failure_callbacks = []
        @ready = false
        @failed = false
        @result = nil
        @exception = nil
      end

      def finished?
        ready? || failed?
      end

      def ready?
        @ready
      end

      def failed?
        @failed
      end

      def wait
        return if finished?
        context.wait_for_any(self)
      end

      def get
        wait
        exception || result
      end

      def set(result)
        raise 'can not fulfil a failed future' if failed?

        @result = result
        @ready = true
      end

      def fail(exception)
        raise 'can not fail a fulfilled future' if ready?

        @exception = exception
        @failed = true
      end

      # When the activity completes successfully, the block will be called with any result
      def done(&block)
        if ready?
          block.call(result)
        else
          # If the future is still outstanding, schedule a callback for invocation by the
          # workflow context when the workflow or activity is finished
          success_callbacks << block
        end
      end

      # When the activity fails, the block will be called with the exception
      def failed(&block)
        if failed?
          block.call(exception)
        else
          # If the future is still outstanding, schedule a callback for invocation by the
          # workflow context when the workflow or activity is finished
          failure_callbacks << block
        end
      end

      def cancel
        return false if finished?

        context.cancel(target, cancelation_id)
      end

      private

      attr_reader :context, :cancelation_id, :result, :exception
    end
  end
end
