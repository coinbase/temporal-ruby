require 'cadence/workflow/serializer/base'

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
                details: Oj.dump(object.details)
              )
          )
        end
      end
    end
  end
end
