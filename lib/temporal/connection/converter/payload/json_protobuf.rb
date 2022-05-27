require 'temporal/json'

module Temporal
  module Connection
    module Converter
      # Workflow Engine Specific: Allows decoding and encoding events from the Java SDK that uses `json/protobuf` encoding
      module Payload
        class JSONProtobuf < JSON
          ENCODING = 'json/protobuf'.freeze

          def encoding
            ENCODING
          end
        end
      end
    end
  end
end
