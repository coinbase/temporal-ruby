require 'temporal/connection/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class QueryAnswer < Base
        include Concerns::Payloads

        def to_proto
          Temporalio::Api::Query::V1::WorkflowQueryResult.new(
            result_type: Temporalio::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_ANSWERED,
            answer: converter.to_query_payloads(object.result)
          )
        end
      end
    end
  end
end
