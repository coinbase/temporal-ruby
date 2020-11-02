require 'fiber'

module Temporal
  class Workflow
    class Future
      attr_reader :target, :callbacks

      def initialize(target, context, cancelation_id: nil)
        @target = target
        @context = context
        @cancelation_id = cancelation_id
        @callbacks = []
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
        context.wait_for(self)
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

      def done(&block)
        # do nothing
        return if failed?

        if ready?
          block.call(result)
        else
          callbacks << block
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
