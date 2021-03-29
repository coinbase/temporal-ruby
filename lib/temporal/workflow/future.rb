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

      # When the activity completes successfully, the block will be called with any result
      def done(&block)
        add_callback do |result, _|
          block.call(result) if ready?
        end
      end

      # When the activity fails, the block will be called with the exception
      def failed(&block)
        add_callback do |_, exception|
          block.call(exception) if failed?
        end
      end

      def cancel
        return false if finished?

        context.cancel(target, cancelation_id)
      end

      private

      def add_callback(&block)
        if finished?
          yield(result, exception)
        else
          # If the future is still outstanding, schedule a callback for invoctaion by the
          # workflow context when the workflow or activity is finished
          callbacks << block
        end
      end

      attr_reader :context, :cancelation_id, :result, :exception
    end
  end
end
