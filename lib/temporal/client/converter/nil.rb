module Temporal
  module Client
    module Converter
      class Nil
        ENCODING = 'binary/null'.freeze

        def encoding
          ENCODING
        end

        def from_payload(payload)
          nil
        end

        def to_payload(data)
          return nil unless data.nil?

          Temporal::Api::Common::V1::Payload.new(
            metadata: { 'encoding' => ENCODING }
          )
        end
      end
    end
  end
end