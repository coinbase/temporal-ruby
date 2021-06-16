module Temporal
  module Concerns
    module Payloads
      def from_payloads(payloads)
        payload_converter.from_payloads(payloads)
      end

      def from_payload(payload)
        payload_converter.from_payload(payload)
      end

      def from_result_payloads(payloads)
        from_payloads(payloads)&.first
      end

      def from_details_payloads(payloads)
        from_payloads(payloads)&.first
      end

      def to_payloads(data)
        payload_converter.to_payloads(data)
      end

      def to_payload(data)
        payload_converter.to_payload(data)
      end

      def to_result_payloads(data)
        to_payloads([data])
      end

      def to_details_payloads(data)
        to_payloads([data])
      end

      private

      def payload_converter
        Temporal.configuration.converter
      end
    end
  end
end
