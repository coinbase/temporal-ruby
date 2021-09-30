require 'temporal/testing/future_registry'

module Temporal
  module Testing
    class WorkflowExecution
      attr_reader :status

      def initialize
        @status = Workflow::ExecutionInfo::RUNNING_STATUS
        @futures = FutureRegistry.new
      end

      def run(&block)
        @fiber = Fiber.new(&block)
        resume
      end

      def resume
        fiber.resume
        @status = Workflow::ExecutionInfo::COMPLETED_STATUS unless fiber.alive?
      rescue StandardError
        @status = Workflow::ExecutionInfo::FAILED_STATUS
      end

      def register_future(id, future)
        futures.register(id, future)
      end

      def complete_future(id, result)
        futures.complete(id, result)
        resume
      end

      def fail_future(id, exception)
        futures.fail(id, exception)
        resume
      end

      private

      attr_reader :fiber, :futures
    end
  end
end
