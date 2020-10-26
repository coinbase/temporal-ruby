require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class Payload < Base
        def to_proto
          Temporal::Api::Common::V1::Payloads.new(
            payloads: [
              Temporal::Api::Common::V1::Payload.new(
                data: JSON.serialize(object)
              )
            ]
          )
        end
      end
    end
  end
end
