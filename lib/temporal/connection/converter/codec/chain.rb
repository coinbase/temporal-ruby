require 'temporal/connection/converter/codec/base'

module Temporal
  module Connection
    module Converter
      module Codec
        # Performs encoding/decoding on the payloads via the given payload codecs. When encoding
        # the codecs are applied last to first meaning the earlier encodings wrap the later ones.
        # When decoding, the codecs are applied first to last to reverse the effect.
        class Chain < Base
          def initialize(payload_codecs:)
            @payload_codecs = payload_codecs
          end

          def encode(payload)
            payload_codecs.reverse_each do |payload_codec|
              payload = payload_codec.encode(payload)
            end
            payload
          end

          def decode(payload)
            payload_codecs.each do |payload_codec|
              payload = payload_codec.decode(payload)
            end
            payload
          end

          private

          attr_reader :payload_codecs
        end
      end
    end
  end
end
