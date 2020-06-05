require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class StartTimer < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::StartTimer,
            startTimerDecisionAttributes:
              TemporalThrift::StartTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s,
                startToFireTimeoutSeconds: object.timeout
              )
          )
        end
      end
    end
  end
end
