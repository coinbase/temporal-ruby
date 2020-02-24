require 'cadence/workflow/serializer/base'

module Cadence
  class Workflow
    module Serializer
      class RecordMarker < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::RecordMarker,
            recordMarkerDecisionAttributes:
              CadenceThrift::RecordMarkerDecisionAttributes.new(
                markerName: object.name,
                details: Oj.dump(object.details)
              )
          )
        end
      end
    end
  end
end
