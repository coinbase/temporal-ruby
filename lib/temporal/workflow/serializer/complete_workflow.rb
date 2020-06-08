require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class CompleteWorkflow < Base
        def to_proto
          Temporal::Proto::Decision.new(
            decisionType: Temporal::Proto::DecisionType::CompleteWorkflowExecution,
            completeWorkflowExecutionDecisionAttributes:
              Temporal::Proto::CompleteWorkflowExecutionDecisionAttributes.new(
                result: Temporal::Proto::Payloads.new(
                  payloads: [
                    Temporal::Proto::Payload.new(
                      data: JSON.serialize(object.result)
                    )
                  ]
                )
              )
          )
        end
      end
    end
  end
end
