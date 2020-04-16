require 'cadence/activity/context'
require 'cadence/metadata/activity'

describe Cadence::Activity::Context do
  let(:client) { instance_double('Cadence::Client::ThriftClient') }
  let(:metadata_hash) { Fabricate(:activity_metadata).to_h }
  let(:metadata) { Cadence::Metadata::Activity.new(metadata_hash) }
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

  describe '#async!' do
    it 'marks activity context as async' do
      expect { subject.async }.to change { subject.async? }.from(false).to(true)
    end
  end

  describe '#async?' do
    subject { context.async? }
    let(:context) { described_class.new(client, metadata) }

    context 'when context is sync' do
      it { is_expected.to eq(false) }
    end

    context 'when context is async' do
      before { context.async }

      it { is_expected.to eq(true) }
    end
  end

  describe '#async_token' do
    it 'returns async token' do
      expect(subject.async_token)
        .to eq(
          Cadence::Activity::AsyncToken.encode(
            metadata.domain,
            metadata.id,
            metadata.workflow_id,
            metadata.workflow_run_id
          )
        )
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
