require 'cadence/workflow/metadata'

describe Cadence::Workflow::Metadata do
  describe '.from_event' do
    subject { described_class.from_event(event_attributes) }
    let(:event_attributes) { Fabricate(:worklfow_execution_started_event_attributes) }

    it 'generates metadata' do
      expect(subject.run_id).to eq(event_attributes.originalExecutionRunId)
      expect(subject.attempt).to eq(event_attributes.attempt)
      expect(subject.headers).to eq({})
    end

    context 'with headers' do
      let(:event_attributes) do
        Fabricate(:worklfow_execution_started_event_attributes, headers: { 'Foo' => 'Bar' })
      end

      it 'assigns headers' do
        expect(subject.headers).to eq('Foo' => 'Bar')
      end
    end
  end

  describe '#initialize' do
    subject { described_class.new(args.to_h) }
    let(:args) { Fabricate(:workflow_metadata) }

    it 'sets the attributes' do
      expect(subject.run_id).to eq(args.run_id)
      expect(subject.attempt).to eq(args.attempt)
      expect(subject.headers).to eq(args.headers)
    end

    it 'returns frozen object' do
      expect(subject).to be_frozen
    end
  end
end
