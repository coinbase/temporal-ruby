require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class RecordMarker < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::RecordMarker,
            recordMarkerDecisionAttributes:
              Temporal::Api::RecordMarkerDecisionAttributes.new(
                markerName: object.name,
                details: Temporal::Api::Payloads.new(
                  payloads:[
                    Temporal::Api::Payload.new(
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
