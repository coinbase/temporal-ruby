require 'fiber'
require 'temporal/workflow/future'

module Temporal
  class Workflow
    # A future that represents a child workflow execution, that additionally tracks whether a 
    # child workflow execution has started.
    class ChildWorkflowFuture < Future
      def initialize(target, context, cancelation_id: nil)
        @started = false
        super
      end

      def started?
        @started
      end

      def start
        raise 'cannot start a fulfilled future' if finished?

        @started = true
      end

      private

      attr_reader :started
    end
  end
end
