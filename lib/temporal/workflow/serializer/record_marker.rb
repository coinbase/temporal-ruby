require 'temporal/workflow/serializer/base'
require 'temporal/workflow/serializer/payload'

module Temporal
  class Workflow
    module Serializer
      class RecordMarker < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_RECORD_MARKER,
            record_marker_command_attributes:
              Temporal::Api::Decision::V1::RecordMarkerCommandAttributes.new(
                marker_name: object.name,
                details: {
                  data: Payload.new(object.details).to_proto
                }
              )
          )
        end
      end
    end
  end
end
