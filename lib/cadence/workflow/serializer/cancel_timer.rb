require 'cadence/workflow/serializer/base'

module Cadence
  class Workflow
    module Serializer
      class CancelTimer < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::CancelTimer,
            cancelTimerDecisionAttributes:
              CadenceThrift::CancelTimerDecisionAttributes.new(
                timerId: object.timer_id.to_s
              )
          )
        end
      end
    end
  end
end
