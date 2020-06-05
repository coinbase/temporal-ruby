require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class FailWorkflow < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::FailWorkflowExecution,
            failWorkflowExecutionDecisionAttributes:
              TemporalThrift::FailWorkflowExecutionDecisionAttributes.new(
                reason: object.reason,
                details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
