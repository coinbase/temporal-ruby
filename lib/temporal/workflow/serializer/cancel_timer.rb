require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class CancelTimer < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::CancelTimer,
            cancelTimerDecisionAttributes:
              TemporalThrift::CancelTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s
              )
          )
        end
      end
    end
  end
end
