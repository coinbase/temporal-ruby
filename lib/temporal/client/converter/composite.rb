module Temporal
  module Client
    module Converter
      class Composite
        class ConverterNotFound < Exception; end
        class MetadataNotSet < Exception; end

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

        def from_payloads(payloads)
          return nil if payloads.nil?
          payloads.payloads.map(&method(:from_payload))
        end

        def to_payload(data)
          converters.each do |converter|
            payload = converter.to_payload(data)
            return payload unless payload.nil?
          end

          raise ConverterNotFound
        end

        def to_payloads(*data)
          Temporal::Api::Common::V1::Payloads.new(
            payloads: data.map(&method(:to_payload))
          )
        end

        private

        attr_reader :converters, :converters_by_encoding
      end
    end
  end
end