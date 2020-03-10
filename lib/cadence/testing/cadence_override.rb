require 'cadence/testing/local_workflow_context'

module Cadence
  module Testing
    module CadenceOverride
      def start_workflow(workflow, *input, **args)
        if Cadence::Testing.disabled?
          super
        elsif Cadence::Testing.local?
          start_locally(workflow, *input, **args)
        end
      end

      private

      def start_locally(workflow, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        context = Cadence::Testing::LocalWorkflowContext.new

        workflow.execute_in_context(context, input)
      end
    end
  end
end
