require_relative 'base'

module Temporal
  module Connection
    module Converter
      module Payload
        class Nil < Base
          ENCODING = 'binary/null'.freeze

          def encoding
            ENCODING
          end

          def from_payload(payload)
            nil
          end

          def to_payload(data)
            return nil unless data.nil?

            Temporalio::Api::Common::V1::Payload.new(
              metadata: { 'encoding' => ENCODING }
            )
          end
        end
      end
    end
  end
end
