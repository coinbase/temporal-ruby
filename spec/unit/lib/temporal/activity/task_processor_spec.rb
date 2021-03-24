require 'temporal/activity/task_processor'
require 'temporal/middleware/chain'

describe Temporal::Activity::TaskProcessor do
  subject { described_class.new(task, namespace, lookup, client, middleware_chain) }

  let(:namespace) { 'test-namespace' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup', find: nil) }
  let(:task) do
    Fabricate(
      :api_activity_task,
      activity_name: activity_name,
      input: Temporal.configuration.converter.to_payloads(*input)
    )
  end
  let(:metadata) { Temporal::Metadata.generate(Temporal::Metadata::ACTIVITY_TYPE, task) }
  let(:activity_name) { 'TestActivity' }
  let(:client) { instance_double('Temporal::Client::GRPCClient') }
  let(:middleware_chain) { Temporal::Middleware::Chain.new }
  let(:input) { ['arg1', 'arg2'] }

  describe '#process' do
    let(:context) { instance_double('Temporal::Activity::Context', async?: false) }

    before do
      allow(Temporal::Metadata)
        .to receive(:generate)
        .with(Temporal::Metadata::ACTIVITY_TYPE, task, namespace)
        .and_return(metadata)
      allow(Temporal::Activity::Context).to receive(:new).with(client, metadata).and_return(context)

      allow(client).to receive(:respond_activity_task_completed)
      allow(client).to receive(:respond_activity_task_failed)

      allow(middleware_chain).to receive(:invoke).and_call_original

      allow(Temporal.metrics).to receive(:timing)
    end

    context 'when activity is not registered' do
      it 'fails the activity task' do
        subject.process

        expect(client)
          .to have_received(:respond_activity_task_failed)
          .with(
            task_token: task.task_token,
            exception: an_instance_of(Temporal::ActivityNotRegistered)
          )
      end

      it 'ignores client exception' do
        allow(client)
          .to receive(:respond_activity_task_failed)
          .and_raise(StandardError)

        subject.process
      end

      it 'calls error_handlers' do
        reported_error = nil
        reported_metadata = nil

        Temporal.configuration.on_error do |error, metadata: nil|
          reported_error = error
          reported_metadata = metadata.to_h
        end

        subject.process

        expect(reported_error).to be_an_instance_of(Temporal::ActivityNotRegistered)
        expect(reported_metadata).to_not be_empty
      end
    end

    context 'when activity is registered' do
      let(:activity_class) { double('Temporal::Activity', execute_in_context: nil) }

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
            .with(task_token: task.task_token, result: 'result')
        end

        it 'ignores client exception' do
          allow(client)
            .to receive(:respond_activity_task_completed)
            .and_raise(StandardError)

          subject.process
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('activity_task.queue_time', an_instance_of(Integer), activity: activity_name)
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
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
        let(:exception) { StandardError.new('activity failed') }

        before { allow(activity_class).to receive(:execute_in_context).and_raise(exception) }

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
            .with(
              task_token: task.task_token,
              exception: exception
            )
        end

        it 'ignores client exception' do
          allow(client)
            .to receive(:respond_activity_task_failed)
            .and_raise(StandardError)

          subject.process
        end

        it 'calls error_handlers' do
          reported_error = nil
          reported_metadata = nil

          Temporal.configuration.on_error do |error, metadata: nil|
            reported_error = error
            reported_metadata = metadata
          end

          subject.process

          expect(reported_error).to be_an_instance_of(StandardError)
          expect(reported_metadata).to be_an_instance_of(Temporal::Metadata::Activity)
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('activity_task.queue_time', an_instance_of(Integer), activity: activity_name)
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with('activity_task.latency', an_instance_of(Integer), activity: activity_name)
        end

        context 'with ScriptError exception' do
          let(:exception) { NotImplementedError.new('this was not supposed to be called') }

          it 'fails the activity task' do
            subject.process

            expect(client)
              .to have_received(:respond_activity_task_failed)
              .with(
                task_token: task.task_token,
                exception: exception
              )
          end
        end

        context 'with SystemExit exception' do
          let(:exception) { SystemExit.new('Houston, we have a problem') }

          it 'does not handle the exception' do
            expect { subject.process }.to raise_error(exception)

            expect(client).not_to have_received(:respond_activity_task_failed)
          end
        end

        context 'with async activity' do
          before { allow(context).to receive(:async?).and_return(true) }

          it 'fails the activity task' do
            subject.process

            expect(client)
              .to have_received(:respond_activity_task_failed)
              .with(task_token: task.task_token, exception: exception)
          end
        end
      end
    end
  end
end
