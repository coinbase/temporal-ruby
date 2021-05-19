module Temporal
  module Client
    module Converter
      class Base
        def initialize(payload_converter:)
          @payload_converter = payload_converter
        end

        def from_payloads(payloads)
          return nil if payloads.nil?
          payloads.payloads.map(&method(:from_payload))
        end

        def from_payload(payload)
          payload_converter.from_payload(payload)
        end

        def to_payloads(data)
          return nil if data.nil?
          Temporal::Api::Common::V1::Payloads.new(
            payloads: data.map(&method(:to_payload))
          )
        end

        def from_result_payloads(payloads)
          payload = payloads&.payloads&.first
          return nil if payload.nil?

          from_payload(payload)
        end

        def from_details_payloads(payloads)
          payload = payloads&.payloads&.first
          return nil if payload.nil?

          from_payload(payload)
        end

        def to_result_payloads(data)
          to_payloads([data])
        end

        def to_details_payloads(data)
          to_payloads([data])
        end

        def to_payload(data)
          payload_converter.to_payload(data)
        end

        private

        attr_reader :payload_converter
      end
    end
  end
end
