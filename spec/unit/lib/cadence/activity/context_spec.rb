require 'cadence/activity/context'

describe Cadence::Activity::Context do
  let(:client) { instance_double('Cadence::Client::ThriftClient') }
  let(:task_token) { SecureRandom.uuid }

  subject { described_class.new(client, task_token) }

  describe '#heartbeat' do
    before { allow(client).to receive(:record_activity_task_heartbeat) }

    it 'records heartbeat' do
      subject.heartbeat

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(task_token: task_token, details: nil)
    end

    it 'records heartbeat with details' do
      subject.heartbeat(foo: :bar)

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(task_token: task_token, details: { foo: :bar })
    end
  end
end
