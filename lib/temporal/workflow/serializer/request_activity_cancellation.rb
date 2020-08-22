require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class RequestActivityCancellation < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::RequestCancelActivityTask,
            requestCancelActivityTaskDecisionAttributes:
              Temporal::Api::RequestCancelActivityTaskDecisionAttributes.new(
                activityId: object.activity_id.to_s
              )
          )
        end
      end
    end
  end
end
