require 'cadence/workflow/serializer/base'
require 'cadence/json'

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
                details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
