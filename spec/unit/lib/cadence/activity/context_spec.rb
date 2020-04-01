require 'cadence/activity/context'
require 'cadence/activity/metadata'

describe Cadence::Activity::Context do
  let(:client) { instance_double('Cadence::Client::ThriftClient') }
  let(:metadata_hash) { Fabricate(:activity_metadata).to_h }
  let(:metadata) { Cadence::Activity::Metadata.new(metadata_hash) }
  let(:task_token) { SecureRandom.uuid }

  subject { described_class.new(client, metadata) }

  describe '#heartbeat' do
    before { allow(client).to receive(:record_activity_task_heartbeat) }

    it 'records heartbeat' do
      subject.heartbeat

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(task_token: metadata.task_token, details: nil)
    end

    it 'records heartbeat with details' do
      subject.heartbeat(foo: :bar)

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(task_token: metadata.task_token, details: { foo: :bar })
    end
  end

  describe '#logger' do
    let(:logger) { instance_double('Logger') }

    before { allow(Cadence).to receive(:logger).and_return(logger) }

    it 'returns Cadence logger' do
      expect(subject.logger).to eq(logger)
    end
  end

  describe '#run_idem' do
    let(:metadata_hash) { Fabricate(:activity_metadata, id: '123', workflow_run_id: '123').to_h }
    let(:expected_uuid) { '601f1889-667e-5aeb-b33b-8c12572835da' }

    it 'returns idempotency token' do
      expect(subject.run_idem).to eq(expected_uuid)
    end
  end

  describe '#workflow_idem' do
    let(:metadata_hash) { Fabricate(:activity_metadata, id: '123', workflow_id: '123').to_h }
    let(:expected_uuid) { '601f1889-667e-5aeb-b33b-8c12572835da' }

    it 'returns idempotency token' do
      expect(subject.workflow_idem).to eq(expected_uuid)
    end
  end

  describe '#headers' do
    let(:metadata_hash) { Fabricate(:activity_metadata, headers: { 'Foo' => 'Bar' }).to_h }

    it 'returns headers' do
      expect(subject.headers).to eq('Foo' => 'Bar')
    end
  end
end
