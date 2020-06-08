require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class StartTimer < Base
        def to_proto
          Temporal::Proto::Decision.new(
            decisionType: Temporal::Proto::DecisionType::StartTimer,
            startTimerDecisionAttributes:
              Temporal::Proto::StartTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s,
                startToFireTimeoutSeconds: object.timeout
              )
          )
        end
      end
    end
  end
end
