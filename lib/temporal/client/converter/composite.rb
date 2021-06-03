require 'temporal/client/converter/base'

module Temporal
  module Client
    module Converter
      class Composite < Base
        class ConverterNotFound < RuntimeError; end
        class MetadataNotSet < RuntimeError; end

        def initialize(payload_converters:)
          @payload_converters = payload_converters
          @payload_converters_by_encoding = {}

          @payload_converters.each do |converter|
            @payload_converters_by_encoding[converter.encoding] = converter
          end
        end

        def from_payload(payload)
          encoding = payload.metadata['encoding']
          if encoding.nil?
            raise MetadataNotSet
          end

          converter = payload_converters_by_encoding[encoding]

          if converter.nil?
            raise ConverterNotFound
          end

          converter.from_payload(payload)
        end

        def to_payload(data)
          payload_converters.each do |converter|
            payload = converter.to_payload(data)
            return payload unless payload.nil?
          end

          raise ConverterNotFound
        end

        private

        attr_reader :payload_converters, :payload_converters_by_encoding
      end
    end
  end
end
