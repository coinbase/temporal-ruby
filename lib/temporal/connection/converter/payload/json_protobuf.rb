require 'temporal/json'

module Temporal
  module Connection
    module Converter
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
