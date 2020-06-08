require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class RecordMarker < Base
        def to_proto
          Temporal::Proto::Decision.new(
            decisionType: Temporal::Proto::DecisionType::RecordMarker,
            recordMarkerDecisionAttributes:
              Temporal::Proto::RecordMarkerDecisionAttributes.new(
                markerName: object.name,
                details: Temporal::Proto::Payloads.new(
                  payloads:[
                    Temporal::Proto::Payload.new(
                      data: JSON.serialize(object.details)
                    )
                  ]
                )
              )
          )
        end
      end
    end
  end
end
