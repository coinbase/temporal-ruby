require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class Priority < Base
        def to_proto
          return unless object

          # Create a Priority proto object
          Temporalio::Api::Common::V1::Priority.new(
            priority_key: object.priority_key,
            fairness_key: object.fairness_key,
            fairness_weight: object.fairness_weight
          )
        end
      end
    end
  end
end 