require 'temporal/metadata/workflow'

describe Temporal::Metadata::Workflow do
  describe '#initialize' do
    subject { described_class.new(args.to_h) }
    let(:args) { Fabricate(:workflow_metadata) }

    it 'sets the attributes' do
      expect(subject.name).to eq(args.name)
      expect(subject.run_id).to eq(args.run_id)
      expect(subject.attempt).to eq(args.attempt)
      expect(subject.headers).to eq(args.headers)
    end

    it { is_expected.to be_frozen }
    it { is_expected.not_to be_activity }
    it { is_expected.not_to be_decision }
    it { is_expected.to be_workflow }
  end
end
