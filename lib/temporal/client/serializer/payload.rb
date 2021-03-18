require 'temporal/client/serializer/base'
require 'temporal/json'

module Temporal
  module Client
    module Serializer
      class Payload < Base
        JSON_ENCODING = 'json/plain'.freeze

        def self.from_proto(proto)
          return if proto.nil? || proto.payloads.empty?

          data = proto.payloads.map do |payload|
            JSON.deserialize(payload.data)
          end

          data.size == 1 ? data.first : data
        end

        def to_proto
          return if object.nil?

          payloads = case object
                     when Array
                       object.map(&method(:payload_for))
                     else
                       [payload_for(object)]
                     end

          Temporal::Api::Common::V1::Payloads.new(
            payloads: payloads
          )
        end

        private

        def payload_for(obj)
          Temporal::Api::Common::V1::Payload.new(
            metadata: { 'encoding' => JSON_ENCODING },
            data: JSON.serialize(obj).b
          )
        end
      end
    end
  end
end
