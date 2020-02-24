require 'cadence/workflow/serializer/base'

module Cadence
  class Workflow
    module Serializer
      class StartTimer < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::StartTimer,
            startTimerDecisionAttributes:
              CadenceThrift::StartTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s,
                startToFireTimeoutSeconds: object.timeout
              )
          )
        end
      end
    end
  end
end
