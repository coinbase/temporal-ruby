module Temporal
  module Concerns
    module Payloads
      def from_payloads(payloads)
        payloads = payload_codec.decodes(payloads)
        payload_converter.from_payloads(payloads)
      end

      def from_payload(payload)
        payload = payload_codec.decode(payload)
        payload_converter.from_payload(payload)
      end

      def from_payload_map_without_codec(payload_map)
        payload_map.map { |key, value| [key, payload_converter.from_payload(value)] }.to_h
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
        payloads = payload_converter.to_payloads(data)
        payload_codec.encodes(payloads)
      end

      def to_payload(data)
        payload = payload_converter.to_payload(data)
        payload_codec.encode(payload)
      end

      def to_payload_map_without_codec(data)
        # skips the payload_codec step because search attributes don't use this pipeline
        data.transform_values do |value|
          payload_converter.to_payload(value)
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

      def payload_converter
        # TODO: Temporary fix, should fo away before the PR
        Temporal.configuration.converter.send(:converter)
      end

      def payload_codec
        Temporal.configuration.payload_codec
      end
    end
  end
end
