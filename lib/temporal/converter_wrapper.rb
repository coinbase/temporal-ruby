# This class provides convenience methods for accessing the converter/codec. It is fully backwards
# compatible with Temporal::Connection::Converter::Base interface, however it adds new convenience
# methods specific to different conversion scenarios.

module Temporal
  class ConverterWrapper
    def initialize(converter, codec)
      @converter = converter
      @codec = codec
    end

    def from_payloads(payloads)
      payloads = codec.decodes(payloads)
      converter.from_payloads(payloads)
    end

    def from_payload(payload)
      payload = codec.decode(payload)
      converter.from_payload(payload)
    end

    def from_payload_map_without_codec(payload_map)
      payload_map.map { |key, value| [key, converter.from_payload(value)] }.to_h
    end

    def from_result_payloads(payloads)
      from_payloads(payloads)&.first
    end

    def from_details_payloads(payloads)
      from_payloads(payloads)&.first
    end

    def from_signal_payloads(payloads)
      from_payloads(payloads)&.first
    end

    def from_query_payloads(payloads)
      from_payloads(payloads)&.first
    end

    def from_payload_map(payload_map)
      payload_map.map { |key, value| [key, from_payload(value)] }.to_h
    end

    def to_payloads(data)
      payloads = converter.to_payloads(data)
      codec.encodes(payloads)
    end

    def to_payload(data)
      payload = converter.to_payload(data)
      codec.encode(payload)
    end

    def to_payload_map_without_codec(data)
      # skips the codec step because search attributes don't use this pipeline
      data.transform_values do |value|
        converter.to_payload(value)
      end
    end

    def to_result_payloads(data)
      to_payloads([data])
    end

    def to_details_payloads(data)
      to_payloads([data])
    end

    def to_signal_payloads(data)
      to_payloads([data])
    end

    def to_query_payloads(data)
      to_payloads([data])
    end

    def to_payload_map(data)
      data.transform_values(&method(:to_payload))
    end

    private

    attr_reader :converter, :codec
  end
end
