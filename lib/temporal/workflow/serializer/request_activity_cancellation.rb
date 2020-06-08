require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class RequestActivityCancellation < Base
        def to_proto
          Temporal::Proto::Decision.new(
            decisionType: Temporal::Proto::DecisionType::RequestCancelActivityTask,
            requestCancelActivityTaskDecisionAttributes:
              Temporal::Proto::RequestCancelActivityTaskDecisionAttributes.new(
                activityId: object.activity_id.to_s
              )
          )
        end
      end
    end
  end
end
