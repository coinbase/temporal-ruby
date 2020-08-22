require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class CompleteWorkflow < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::CompleteWorkflowExecution,
            completeWorkflowExecutionDecisionAttributes:
              Temporal::Api::CompleteWorkflowExecutionDecisionAttributes.new(
                result: Temporal::Api::Payloads.new(
                  payloads: [
                    Temporal::Api::Payload.new(
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
