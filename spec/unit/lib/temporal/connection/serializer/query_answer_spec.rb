require 'temporal/connection/serializer/query_failure'
require 'temporal/workflow/query_result'
require 'temporal/concerns/payloads'

describe Temporal::Connection::Serializer::QueryAnswer do
  class TestDeserializer
    extend Temporal::Concerns::Payloads
  end

  describe 'to_proto' do
    let(:query_result) { Temporal::Workflow::QueryResult.answer(42) }

    it 'produces a protobuf' do
      result = described_class.new(query_result).to_proto

      expect(result).to be_a(Temporal::Api::Query::V1::WorkflowQueryResult)
      expect(result.result_type).to eq(Temporal::Api::Enums::V1::QueryResultType.lookup(
        Temporal::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_ANSWERED)
      )
      expect(result.answer).to eq(TestDeserializer.to_query_payloads(42))
    end
  end
end
