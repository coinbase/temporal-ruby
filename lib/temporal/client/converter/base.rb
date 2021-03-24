require 'temporal/json'

module Temporal
  module Client
    module Converter
      class Base
        def from_payloads(payloads)
          return nil if payloads.nil?
          payloads.payloads.map(&method(:from_payload))
        end

        def from_payload(payload)
          rasise NotImplementedError
        end

        def to_payloads(*data)
          Temporal::Api::Common::V1::Payloads.new(
            payloads: data.map(&method(:to_payload))
          )
        end

        def to_payload(data)
          rasise NotImplementedError
        end
      end
    end
  end
end
