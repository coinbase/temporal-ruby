require 'fiber'
require 'temporal/workflow/future'

module Temporal
  class Workflow
    # A future that represents a child workflow execution
    class ChildWorkflowFuture < Future
      attr_reader :child_workflow_execution_future

      def initialize(target, context, cancelation_id: nil, child_workflow_execution_future:)
        super(target, context, cancelation_id: nil)
        @child_workflow_execution_future = child_workflow_execution_future
      end
    end
  end
end
