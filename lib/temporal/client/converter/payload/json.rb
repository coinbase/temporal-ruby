require 'temporal/json'

module Temporal
  module Client
    module Converter
      module Payload
        class JSON
          ENCODING = 'json/plain'.freeze

          def encoding
            ENCODING
          end

          def from_payload(payload)
            Temporal::JSON.deserialize(payload.data)
          end

          def to_payload(data)
            Temporal::Api::Common::V1::Payload.new(
              metadata: { 'encoding' => ENCODING },
              data: Temporal::JSON.serialize(data).b
            )
          end
        end
      end
    end
  end
end
