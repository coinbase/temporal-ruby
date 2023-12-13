require 'temporal/json'
require_relative 'base'

module Temporal
  module Connection
    module Converter
      module Payload
        class JSON < Base
          ENCODING = 'json/plain'.freeze

          def encoding
            ENCODING
          end

          def from_payload(payload)
            Temporal::JSON.deserialize(payload.data, options)
          end

          def to_payload(data)
            Temporalio::Api::Common::V1::Payload.new(
              metadata: { 'encoding' => ENCODING },
              data: Temporal::JSON.serialize(data, options).b
            )
          end
        end
      end
    end
  end
end
