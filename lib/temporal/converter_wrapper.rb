# This class provides convenience methods for accessing the converter. it is backwards compatible
# with Temporal::Connection::Converter::Base interface, however it adds new methods specific to
# different conversion scenarios.

module Temporal
  class ConverterWrapper
    def initialize(converter)
      @converter = converter
    end

    def from_payloads(payloads)
      converter.from_payloads(payloads)
    end

    def from_payload(payload)
      converter.from_payload(payload)
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

    def from_payload_map(payload_map)
      payload_map.map { |key, value| [key, from_payload(value)] }.to_h
    end

    def to_payloads(data)
      converter.to_payloads(data)
    end

    def to_payload(data)
      converter.to_payload(data)
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

    def to_payload_map(data)
      data.transform_values(&method(:to_payload))
    end

    private

    attr_reader :converter
  end
end
