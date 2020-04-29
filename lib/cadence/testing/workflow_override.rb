require 'cadence/testing/local_workflow_context'

module Cadence
  module Testing
    module WorkflowOverride
      def execute_locally(*input)
        context = Cadence::Testing::LocalWorkflowContext.new
        execute_in_context(context, input)
      end
    end
  end
end
