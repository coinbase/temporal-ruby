require 'temporal/connection/serializer/query_failure'
require 'temporal/workflow/query_result'

describe Temporal::Connection::Serializer::QueryAnswer do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end

  describe 'to_proto' do
    let(:query_result) { Temporal::Workflow::QueryResult.answer(42) }

    it 'produces a protobuf' do
      result = described_class.new(query_result, converter).to_proto

      expect(result).to be_a(Temporalio::Api::Query::V1::WorkflowQueryResult)
      expect(result.result_type).to eq(Temporalio::Api::Enums::V1::QueryResultType.lookup(
        Temporalio::Api::Enums::V1::QueryResultType::QUERY_RESULT_TYPE_ANSWERED)
      )
      expect(result.answer).to eq(converter.to_query_payloads(42))
    end
  end
end
