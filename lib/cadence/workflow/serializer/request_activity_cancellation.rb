require 'cadence/workflow/serializer/base'

module Cadence
  class Workflow
    module Serializer
      class RequestActivityCancellation < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::RequestCancelActivityTask,
            requestCancelActivityTaskDecisionAttributes:
              CadenceThrift::RequestCancelActivityTaskDecisionAttributes.new(
                activityId: object.activity_id.to_s
              )
          )
        end
      end
    end
  end
end
