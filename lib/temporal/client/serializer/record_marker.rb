require 'temporal/client/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Client
    module Serializer
      class RecordMarker < Base
        include Concerns::Payloads

        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_RECORD_MARKER,
            record_marker_command_attributes:
              Temporal::Api::Command::V1::RecordMarkerCommandAttributes.new(
                marker_name: object.name,
                details: {
                  'data' => to_details_payloads(object.details)
                }
              )
          )
        end
      end
    end
  end
end
