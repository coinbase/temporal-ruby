require 'temporal/connection/serializer/base'

module Temporal
  module Connection
    module Serializer
      class QueryFailure < Base
        def to_proto
          Temporal::Api::Query::V1::WorkflowQueryResult.new(
            result_type: Temporal::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_FAILED,
            error_message: object.error.message
          )
        end
      end
    end
  end
end
