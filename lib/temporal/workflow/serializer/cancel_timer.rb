require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class CancelTimer < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::CancelTimer,
            cancelTimerDecisionAttributes:
              Temporal::Api::CancelTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s
              )
          )
        end
      end
    end
  end
end
