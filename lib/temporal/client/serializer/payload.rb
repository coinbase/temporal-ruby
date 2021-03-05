require 'temporal/client/serializer/base'
require 'temporal/json'

module Temporal
  module Client
    module Serializer
      class Payload < Base
        JSON_ENCODING = 'json/plain'.freeze

        def self.from_proto(proto)
          return if proto.nil? || proto.payloads.empty?

          binary = proto.payloads.first.data
          JSON.deserialize(binary)
        end

        def to_proto
          return if object.nil?

          Temporal::Api::Common::V1::Payloads.new(
            payloads: [
              Temporal::Api::Common::V1::Payload.new(
                metadata: { 'encoding' => JSON_ENCODING },
                data: JSON.serialize(object).b
              )
            ]
          )
        end
      end
    end
  end
end
