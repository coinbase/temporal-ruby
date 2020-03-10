require 'cadence/testing/local_workflow_context'

module Cadence
  module Testing
    module WorkflowOverride
      def execute_locally(*input)
        context = Cadence::Testing::LocalWorkflowContext.new
        Cadence::ThreadLocalContext.set(context)

        workflow = new(context)
        result = workflow.execute(*input)

        result
      end
    end
  end
end
