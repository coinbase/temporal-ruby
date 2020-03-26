require 'cadence/workflow/serializer/base'
require 'cadence/json'

module Cadence
  class Workflow
    module Serializer
      class CompleteWorkflow < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::CompleteWorkflowExecution,
            completeWorkflowExecutionDecisionAttributes:
              CadenceThrift::CompleteWorkflowExecutionDecisionAttributes.new(
                result: JSON.serialize(object.result)
              )
          )
        end
      end
    end
  end
end
