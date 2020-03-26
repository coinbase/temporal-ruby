require 'cadence/workflow/serializer/base'
require 'cadence/json'

module Cadence
  class Workflow
    module Serializer
      class FailWorkflow < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::FailWorkflowExecution,
            failWorkflowExecutionDecisionAttributes:
              CadenceThrift::FailWorkflowExecutionDecisionAttributes.new(
                reason: object.reason,
                details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
