require 'temporal/workflow/serializer/base'

module Temporal
  class Workflow
    module Serializer
      class StartTimer < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::StartTimer,
            startTimerDecisionAttributes:
              Temporal::Api::StartTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s,
                startToFireTimeoutSeconds: object.timeout
              )
          )
        end
      end
    end
  end
end
