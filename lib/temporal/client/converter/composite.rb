require 'temporal/client/converter/base'

module Temporal
  module Client
    module Converter
      class Composite < Base
        class ConverterNotFound < RuntimeError; end
        class MetadataNotSet < RuntimeError; end

        def initialize(converters:)
          @converters = converters
          @converters_by_encoding = {}
          converters.each do |converter|
            @converters_by_encoding[converter.encoding] = converter
          end
        end

        def from_payload(payload)
          encoding = payload.metadata['encoding']
          if encoding.nil?
            raise MetadataNotSet
          end

          converter = converters_by_encoding[encoding]

          if converter.nil?
            raise ConverterNotFound
          end

          converter.from_payload(payload)
        end

        def to_payload(data)
          converters.each do |converter|
            payload = converter.to_payload(data)
            return payload unless payload.nil?
          end

          raise ConverterNotFound
        end

        private

        attr_reader :converters, :converters_by_encoding
      end
    end
  end
end
