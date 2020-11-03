require 'temporal/client/serializer/base'
require 'temporal/json'

module Temporal
  module Client
    module Serializer
      class Payload < Base
        JSON_ENCODING = 'json/plain'.freeze

        def to_proto
          return Temporal::Api::Common::V1::Payloads.new if object.nil?

          Temporal::Api::Common::V1::Payloads.new(
            payloads: [
              Temporal::Api::Common::V1::Payload.new(
                metadata: { 'encoding' => JSON_ENCODING },
                data: JSON.serialize(object)
              )
            ]
          )
        end
      end
    end
  end
end
