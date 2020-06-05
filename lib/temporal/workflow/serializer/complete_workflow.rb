require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class CompleteWorkflow < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::CompleteWorkflowExecution,
            completeWorkflowExecutionDecisionAttributes:
              TemporalThrift::CompleteWorkflowExecutionDecisionAttributes.new(
                result: JSON.serialize(object.result)
              )
          )
        end
      end
    end
  end
end
