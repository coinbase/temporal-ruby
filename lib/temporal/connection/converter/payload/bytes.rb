require 'temporal/json'
require_relative 'base'

module Temporal
  module Connection
    module Converter
      module Payload
        class Bytes < Base
          ENCODING = 'binary/plain'.freeze

          def encoding
            ENCODING
          end

          def from_payload(payload)
            payload.data
          end

          def to_payload(data)
            return nil unless data.is_a?(String) && data.encoding == Encoding::ASCII_8BIT

            Temporalio::Api::Common::V1::Payload.new(
              metadata: { 'encoding' => ENCODING },
              data: data
            )
          end
        end
      end
    end
  end
end
