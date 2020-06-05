require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class RequestActivityCancellation < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::RequestCancelActivityTask,
            requestCancelActivityTaskDecisionAttributes:
              TemporalThrift::RequestCancelActivityTaskDecisionAttributes.new(
                activityId: object.activity_id.to_s
              )
          )
        end
      end
    end
  end
end
