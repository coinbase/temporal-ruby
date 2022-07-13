require 'temporal/testing/future_registry'
require 'temporal/workflow/status'

module Temporal
  module Testing
    class WorkflowExecution
      attr_reader :status, :search_attributes

      def initialize(initial_search_attributes: {})
        @status = Workflow::Status::RUNNING
        @futures = FutureRegistry.new
        @search_attributes = initial_search_attributes
      end

      def run(&block)
        @fiber = Fiber.new(&block)
        resume
      end

      def resume
        fiber.resume
        @status = Workflow::Status::COMPLETED unless fiber.alive?
      rescue StandardError
        @status = Workflow::Status::FAILED
      end

      def register_future(token, future)
        futures.register(token, future)
      end

      def complete_activity(token, result)
        futures.complete(token, result)
        resume
      end

      def fail_activity(token, exception)
        futures.fail(token, exception)
        resume
      end

      def upsert_search_attributes(search_attributes)
        @search_attributes.merge!(search_attributes)
      end

      private

      attr_reader :fiber, :futures
    end
  end
end
