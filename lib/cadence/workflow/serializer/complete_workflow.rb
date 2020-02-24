require 'cadence/workflow/serializer/base'

module Cadence
  class Workflow
    module Serializer
      class CompleteWorkflow < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::CompleteWorkflowExecution,
            completeWorkflowExecutionDecisionAttributes:
              CadenceThrift::CompleteWorkflowExecutionDecisionAttributes.new(
                result: Oj.dump(object.result)
              )
          )
        end
      end
    end
  end
end
