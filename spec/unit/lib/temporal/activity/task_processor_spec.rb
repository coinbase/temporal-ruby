require 'temporal/activity/task_processor'
require 'temporal/configuration'
require 'temporal/metric_keys'
require 'temporal/middleware/chain'
require 'temporal/scheduled_thread_pool'

describe Temporal::Activity::TaskProcessor do
  subject { described_class.new(task, namespace, lookup, middleware_chain, config, heartbeat_thread_pool) }

  let(:namespace) { 'test-namespace' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup', find: nil) }
  let(:task) do
    Fabricate(
      :api_activity_task,
      activity_name: activity_name,
      input: config.converter.to_payloads(input)
    )
  end
  let(:metadata) { Temporal::Metadata.generate_activity_metadata(task, namespace) }
  let(:workflow_name) { task.workflow_type.name }
  let(:activity_name) { 'TestActivity' }
  let(:connection) { instance_double('Temporal::Connection::GRPC') }
  let(:middleware_chain) { Temporal::Middleware::Chain.new }
  let(:config) { Temporal::Configuration.new }
  let(:heartbeat_thread_pool) { Temporal::ScheduledThreadPool.new(2, config, {}) }
  let(:input) { %w[arg1 arg2] }

  describe '#process' do
    let(:heartbeat_check_scheduled) { nil }
    let(:context) do
      instance_double('Temporal::Activity::Context', async?: false,
                                                     heartbeat_check_scheduled: heartbeat_check_scheduled)
    end

    before do
      allow(Temporal::Connection)
        .to receive(:generate)
        .with(config.for_connection)
        .and_return(connection)
      allow(Temporal::Metadata)
        .to receive(:generate_activity_metadata)
        .with(task, namespace)
        .and_return(metadata)
      allow(Temporal::Activity::Context).to receive(:new).with(connection, metadata, config,
                                                               heartbeat_thread_pool).and_return(context)

      allow(connection).to receive(:respond_activity_task_completed)
      allow(connection).to receive(:respond_activity_task_failed)

      allow(middleware_chain).to receive(:invoke).and_call_original

      allow(Temporal.metrics).to receive(:timing)

      # Skip sleeps during retries to speed up the test.
      allow(Temporal::Connection::Retryer).to receive(:sleep).and_return(nil)
    end

    context 'when activity is not registered' do
      it 'fails the activity task' do
        subject.process

        expect(connection)
          .to have_received(:respond_activity_task_failed)
          .with(
            namespace: namespace,
            task_token: task.task_token,
            exception: an_instance_of(Temporal::ActivityNotRegistered)
          )
      end

      it 'ignores connection exception' do
        allow(connection)
          .to receive(:respond_activity_task_failed)
          .and_raise(StandardError)

        subject.process
      end

      it 'calls error_handlers' do
        reported_error = nil
        reported_metadata = nil

        config.on_error do |error, metadata: nil|
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

          expect(connection)
            .to have_received(:respond_activity_task_completed)
            .with(namespace: namespace, task_token: task.task_token, result: 'result')
        end

        context 'when there is an outstanding scheduled heartbeat' do
          let(:heartbeat_check_scheduled) do
            Temporal::ScheduledThreadPool::ScheduledItem.new(id: :foo, canceled: false)
          end
          it 'it gets canceled' do
            subject.process

            expect(heartbeat_check_scheduled.canceled).to eq(true)
          end
        end

        it 'ignores connection exception' do
          allow(connection)
            .to receive(:respond_activity_task_completed)
            .and_raise(StandardError)

          subject.process
        end

        it 'sends queue_time metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with(
              Temporal::MetricKeys::ACTIVITY_TASK_QUEUE_TIME,
              an_instance_of(Integer),
              activity: activity_name,
              namespace: namespace,
              workflow: workflow_name
            )
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with(
              Temporal::MetricKeys::ACTIVITY_TASK_LATENCY,
              an_instance_of(Integer),
              activity: activity_name,
              namespace: namespace,
              workflow: workflow_name
            )
        end

        context 'with async activity' do
          before { allow(context).to receive(:async?).and_return(true) }

          it 'does not complete the activity task' do
            subject.process

            expect(connection).not_to have_received(:respond_activity_task_completed)
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

          expect(connection)
            .to have_received(:respond_activity_task_failed)
            .with(
              namespace: namespace,
              task_token: task.task_token,
              exception: exception
            )
        end

        it 'ignores connection exception' do
          allow(connection)
            .to receive(:respond_activity_task_failed)
            .and_raise(StandardError)

          subject.process
        end

        it 'calls error_handlers' do
          reported_error = nil
          reported_metadata = nil

          config.on_error do |error, metadata: nil|
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
            .with(
              Temporal::MetricKeys::ACTIVITY_TASK_QUEUE_TIME,
              an_instance_of(Integer),
              activity: activity_name,
              namespace: namespace,
              workflow: workflow_name
            )
        end

        it 'sends latency metric' do
          subject.process

          expect(Temporal.metrics)
            .to have_received(:timing)
            .with(
              Temporal::MetricKeys::ACTIVITY_TASK_LATENCY,
              an_instance_of(Integer),
              activity: activity_name,
              namespace: namespace,
              workflow: workflow_name
            )
        end

        context 'with ScriptError exception' do
          let(:exception) { NotImplementedError.new('this was not supposed to be called') }

          it 'fails the activity task' do
            subject.process

            expect(connection)
              .to have_received(:respond_activity_task_failed)
              .with(
                namespace: namespace,
                task_token: task.task_token,
                exception: exception
              )
          end
        end

        context 'with SystemExit exception' do
          let(:exception) { SystemExit.new('Houston, we have a problem') }

          it 'does not handle the exception' do
            expect { subject.process }.to raise_error(exception)

            expect(connection).not_to have_received(:respond_activity_task_failed)
          end
        end

        context 'with async activity' do
          before { allow(context).to receive(:async?).and_return(true) }

          it 'fails the activity task' do
            subject.process

            expect(connection)
              .to have_received(:respond_activity_task_failed)
              .with(
                namespace: namespace,
                task_token: task.task_token,
                exception: exception
              )
          end
        end
      end
    end
  end
end
