require 'cadence/activity/task_processor'
require 'cadence/middleware/chain'

describe Cadence::Activity::TaskProcessor do
  subject { described_class.new(task, domain, lookup, client, middleware_chain) }

  let(:domain) { 'test-domain' }
  let(:lookup) { instance_double('Cadence::ExecutableLookup', find: nil) }
  let(:task) do
    Fabricate(:activity_task, activity_name: activity_name, input: Cadence::JSON.serialize(input))
  end
  let(:metadata) { Cadence::Metadata.generate(Cadence::Metadata::ACTIVITY_TYPE, task) }
  let(:activity_name) { 'TestActivity' }
  let(:client) { instance_double('Cadence::Client::ThriftClient') }
  let(:middleware_chain) { Cadence::Middleware::Chain.new }
  let(:input) { ['arg1', 'arg2'] }

  describe '#process' do
    let(:context) { instance_double('Cadence::Activity::Context', async?: false) }

    before do
      allow(Cadence::Metadata)
        .to receive(:generate)
        .with(Cadence::Metadata::ACTIVITY_TYPE, task, domain)
        .and_return(metadata)
      allow(Cadence::Activity::Context).to receive(:new).with(client, metadata).and_return(context)

      allow(client).to receive(:respond_activity_task_completed)
      allow(client).to receive(:respond_activity_task_failed)

      allow(middleware_chain).to receive(:invoke).and_call_original

      allow(Cadence.metrics).to receive(:timing)
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

        it 'invokes the middleware chain' do
          subject.process

          expect(middleware_chain).to have_received(:invoke).with(metadata)
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

        it 'sends queue_time metric' do
          subject.process

          expect(Cadence.metrics)
            .to have_received(:timing)
            .with('activity_task.queue_time', an_instance_of(Integer), activity: activity_name)
        end

        it 'sends latency metric' do
          subject.process

          expect(Cadence.metrics)
            .to have_received(:timing)
            .with('activity_task.latency', an_instance_of(Integer), activity: activity_name)
        end

        context 'with async activity' do
          before { allow(context).to receive(:async?).and_return(true) }

          it 'does not complete the activity task' do
            subject.process

            expect(client).not_to have_received(:respond_activity_task_completed)
          end
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

        it 'invokes the middleware chain' do
          subject.process

          expect(middleware_chain).to have_received(:invoke).with(metadata)
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

        it 'sends queue_time metric' do
          subject.process

          expect(Cadence.metrics)
            .to have_received(:timing)
            .with('activity_task.queue_time', an_instance_of(Integer), activity: activity_name)
        end

        it 'sends latency metric' do
          subject.process

          expect(Cadence.metrics)
            .to have_received(:timing)
            .with('activity_task.latency', an_instance_of(Integer), activity: activity_name)
        end

        context 'with async activity' do
          before { allow(context).to receive(:async?).and_return(true) }

          it 'fails the activity task' do
            subject.process

            expect(client)
              .to have_received(:respond_activity_task_failed)
              .with(task_token: task.taskToken, reason: 'StandardError', details: 'activity failed')
          end
        end
      end
    end
  end
end
