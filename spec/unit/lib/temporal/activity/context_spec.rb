require 'temporal/activity/context'
require 'temporal/metadata/activity'
require 'temporal/scheduled_thread_pool'

describe Temporal::Activity::Context do
  let(:connection) { instance_double('Temporal::Connection::GRPC') }
  let(:metadata_hash) { Fabricate(:activity_metadata).to_h }
  let(:metadata) { Temporal::Metadata::Activity.new(**metadata_hash) }
  let(:config) { Temporal::Configuration.new }
  let(:task_token) { SecureRandom.uuid }
  let(:heartbeat_thread_pool) { Temporal::ScheduledThreadPool.new(1, config, {}) }
  let(:heartbeat_response) { Fabricate(:api_record_activity_heartbeat_response) }

  subject { described_class.new(connection, metadata, config, heartbeat_thread_pool) }

  describe '#heartbeat' do
    before { allow(connection).to receive(:record_activity_task_heartbeat).and_return(heartbeat_response) }

    it 'records heartbeat' do
      subject.heartbeat

      expect(connection)
        .to have_received(:record_activity_task_heartbeat)
        .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
    end

    it 'records heartbeat with details' do
      subject.heartbeat(foo: :bar)

      expect(connection)
        .to have_received(:record_activity_task_heartbeat)
        .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { foo: :bar })
    end

    context 'cancellation' do
      let(:heartbeat_response) { Fabricate(:api_record_activity_heartbeat_response, cancel_requested: true) }
      it 'sets when cancelled' do
        subject.heartbeat
        expect(subject.cancel_requested).to be(true)
      end
    end

    context 'throttling' do
      context 'skips after the first heartbeat' do
        let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_timeout: 30).to_h }
        it 'discard duplicates after first when quickly completes' do
          10.times do |i|
            subject.heartbeat(iteration: i)
          end

          expect(connection)
            .to have_received(:record_activity_task_heartbeat)
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 0 })
            .once
        end
      end

      context 'resumes' do
        let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_timeout: 0.1).to_h }
        it 'more heartbeats after time passes' do
          subject.heartbeat(iteration: 1)
          subject.heartbeat(iteration: 2) # skipped because 3 will overwrite
          subject.heartbeat(iteration: 3)
          sleep 0.1
          subject.heartbeat(iteration: 4)

          # Shutdown to drain remaining threads
          heartbeat_thread_pool.shutdown

          expect(connection)
            .to have_received(:record_activity_task_heartbeat)
            .ordered
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 1 })
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 3 })
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 4 })
        end
      end

      it 'no heartbeat check scheduled when max interval is zero' do
        config.timeouts = { max_heartbeat_throttle_interval: 0 }
        subject.heartbeat

        expect(connection)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)

        expect(subject.heartbeat_check_scheduled).to be_nil
      end
    end
  end

  describe '#last_heartbeat_throttled' do
    before { allow(connection).to receive(:record_activity_task_heartbeat).and_return(heartbeat_response) }

    let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_timeout: 3).to_h }

    it 'true when throttled, false when not' do
      subject.heartbeat(iteration: 1)
      expect(subject.last_heartbeat_throttled).to be(false)
      subject.heartbeat(iteration: 2)
      expect(subject.last_heartbeat_throttled).to be(true)

      # Shutdown to drain remaining threads
      heartbeat_thread_pool.shutdown
    end
  end

  describe '#heartbeat_details' do
    let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_details: 4).to_h }

    it 'returns the most recent heartbeat details' do
      expect(subject.heartbeat_details).to eq 4
    end
  end

  describe '#async!' do
    it 'marks activity context as async' do
      expect { subject.async }.to change { subject.async? }.from(false).to(true)
    end
  end

  describe '#async?' do
    subject { context.async? }
    let(:context) { described_class.new(connection, metadata, nil, nil) }

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
          Temporal::Activity::AsyncToken.encode(
            metadata.namespace,
            metadata.id,
            metadata.workflow_id,
            metadata.workflow_run_id
          )
        )
    end
  end

  describe '#logger' do
    let(:logger) { instance_double('Logger') }

    before { allow(Temporal).to receive(:logger).and_return(logger) }

    it 'returns Temporal logger' do
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

  describe '#name' do
    it 'returns the class name of the activity' do
      expect(subject.name).to eq('TestActivity')
    end
  end
end
