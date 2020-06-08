require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class CancelTimer < Base
        def to_proto
          Temporal::Proto::Decision.new(
            decisionType: Temporal::Proto::DecisionType::CancelTimer,
            cancelTimerDecisionAttributes:
              Temporal::Proto::CancelTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s
              )
          )
        end
      end
    end
  end
end
