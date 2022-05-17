require 'temporal/workflow/query_result'

describe Temporal::Workflow::QueryResult do
  describe '.answer' do
    it 'returns an anwer query result' do
      result = described_class.answer(42)

      expect(result).to be_a(Temporal::Workflow::QueryResult::Answer)
      expect(result).to be_frozen
      expect(result.result).to eq(42)
    end
  end

  describe '.failure' do
    let(:error) { StandardError.new('Test query failure') }

    it 'returns a failure query result' do
      result = described_class.failure(error)

      expect(result).to be_a(Temporal::Workflow::QueryResult::Failure)
      expect(result).to be_frozen
      expect(result.error).to eq(error)
    end
  end
end
