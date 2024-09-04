require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class RecordMarker < Base
        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_RECORD_MARKER,
            record_marker_command_attributes:
              Temporalio::Api::Command::V1::RecordMarkerCommandAttributes.new(
                marker_name: object.name,
                details: {
                  'data' => converter.to_details_payloads(object.details)
                }
              )
          )
        end
      end
    end
  end
end
