require 'fiber'
require 'temporal/workflow/future'

module Temporal
  class Workflow
    # A future that represents a child workflow execution
    class ChildWorkflowFuture < Future
      attr_reader :child_workflow_execution_future

      def initialize(target, context, cancelation_id: nil)
        super

        # create a future which will keep track of when the child workflow starts
        @child_workflow_execution_future = Future.new(target, context, cancelation_id: cancelation_id)
      end
    end
  end
end
