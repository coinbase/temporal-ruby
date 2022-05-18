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

      def payload_converter
        Temporal.configuration.converter
      end
    end
  end
end
