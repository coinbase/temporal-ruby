require 'cadence/activity/async_token'

describe Cadence::Activity::AsyncToken do
  let(:domain) { 'test-domain' }
  let(:activity_id) { '42' }
  let(:workflow_id) { '01f213ec-f4ea-4dd5-a0e3-fca4114b3b68' }
  let(:run_id) { 'a469365f-d1ea-47d9-a28d-f5c45008591d' }
  let(:token) { 'dGVzdC1kb21haW58NDJ8MDFmMjEzZWMtZjRlYS00ZGQ1LWEwZTMtZmNhNDExNGIzYjY4fGE0NjkzNjVmLWQxZWEtNDdkOS1hMjhkLWY1YzQ1MDA4NTkxZA==' }

  describe '.encode' do
    it 'returns a base64 encoded token' do
      expect(described_class.encode(domain, activity_id, workflow_id, run_id)).to eq(token)
    end
  end

  describe '.decode' do
    subject { described_class.decode(token) }

    it 'return an instance of AsyncToken' do
      expect(subject).to be_an_instance_of(described_class)
    end

    it 'has decoded all the parts' do
      expect(subject.domain).to eq(domain)
      expect(subject.activity_id).to eq(activity_id)
      expect(subject.workflow_id).to eq(workflow_id)
      expect(subject.run_id).to eq(run_id)
    end
  end

  describe '#to_s' do
    subject { described_class.new(domain, activity_id, workflow_id, run_id) }

    it 'returns base64 encoded token' do
      expect(subject.to_s).to eq(token)
    end

    it 'returns a frozen string' do
      expect(subject.to_s).to be_frozen
    end
  end
end
