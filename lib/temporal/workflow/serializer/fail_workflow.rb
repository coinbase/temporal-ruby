require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class FailWorkflow < Base
        def to_proto
          Temporal::Proto::Decision.new(
            decisionType: Temporal::Proto::DecisionType::FailWorkflowExecution,
            failWorkflowExecutionDecisionAttributes:
              Temporal::Proto::FailWorkflowExecutionDecisionAttributes.new(
                failure: Temporal::Proto::Failure.new(message: object.reason)
                # reason: object.reason,
                # details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
