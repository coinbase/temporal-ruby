require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class FailWorkflow < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::FailWorkflowExecution,
            failWorkflowExecutionDecisionAttributes:
              Temporal::Api::FailWorkflowExecutionDecisionAttributes.new(
                failure: Temporal::Api::Failure.new(message: object.reason)
                # reason: object.reason,
                # details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
