require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class RecordMarker < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::RecordMarker,
            recordMarkerDecisionAttributes:
              TemporalThrift::RecordMarkerDecisionAttributes.new(
                markerName: object.name,
                details: JSON.serialize(object.details)
              )
          )
        end
      end
    end
  end
end
