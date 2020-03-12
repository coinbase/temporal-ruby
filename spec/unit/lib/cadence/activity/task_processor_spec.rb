require 'cadence/activity/task_processor'

describe Cadence::Activity::TaskProcessor do
  subject { described_class.new(task, lookup) }

  let(:lookup) { instance_double('Cadence::ExecutableLookup', find: nil) }
  let(:task) { Fabricate(:activity_task, activity_name: activity_name, input: Oj.dump(input)) }
  let(:metadata) { Cadence::Activity::Metadata.from_task(task) }
  let(:activity_name) { 'TestActivity' }
  let(:client) { instance_double('Cadence::Client::ThriftClient') }
  let(:input) { ['arg1', 'arg2'] }

  before { allow(Cadence::Client).to receive(:generate).and_return(client) }

  describe '#process' do
    let(:context) { instance_double('Cadence::Activity::Context') }

    before do
      allow(Cadence::Activity::Metadata).to receive(:from_task).with(task).and_return(metadata)
      allow(Cadence::Activity::Context).to receive(:new).with(client, metadata).and_return(context)

      allow(client).to receive(:respond_activity_task_completed)
      allow(client).to receive(:respond_activity_task_failed)
    end

    context 'when activity is not registered' do
      it 'fails the activity task' do
        subject.process

        expect(client)
          .to have_received(:respond_activity_task_failed)
          .with(
            task_token: task.taskToken,
            reason: 'ActivityNotRegistered',
            details: 'Activity is not registered with this worker'
          )
      end

      it 'ignores client exception' do
        allow(client)
          .to receive(:respond_activity_task_failed)
          .and_raise(StandardError)

        subject.process
      end
    end

    context 'when activity is registered' do
      let(:activity_class) { double('Cadence::Activity', execute_in_context: nil) }

      before do
        allow(lookup).to receive(:find).with(activity_name).and_return(activity_class)
      end

      context 'when activity completes' do
        before { allow(activity_class).to receive(:execute_in_context).and_return('result') }

        it 'runs the specified activity' do
          subject.process

          expect(activity_class).to have_received(:execute_in_context).with(context, input)
        end

        it 'completes the activity task' do
          subject.process

          expect(client)
            .to have_received(:respond_activity_task_completed)
            .with(task_token: task.taskToken, result: 'result')
        end

        it 'ignores client exception' do
          allow(client)
            .to receive(:respond_activity_task_completed)
            .and_raise(StandardError)

          subject.process
        end
      end

      context 'when activity raises an exception' do
        before do
          allow(activity_class)
            .to receive(:execute_in_context)
            .and_raise(StandardError, 'activity failed')
        end

        it 'runs the specified activity' do
          subject.process

          expect(activity_class).to have_received(:execute_in_context).with(context, input)
        end

        it 'fails the activity task' do
          subject.process

          expect(client)
            .to have_received(:respond_activity_task_failed)
            .with(task_token: task.taskToken, reason: 'StandardError', details: 'activity failed')
        end

        it 'ignores client exception' do
          allow(client)
            .to receive(:respond_activity_task_failed)
            .and_raise(StandardError)

          subject.process
        end
      end
    end

  end
end
