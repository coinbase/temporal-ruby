require 'temporal/configuration'
require 'temporal/metric_keys'
require 'temporal/middleware/entry'
require 'temporal/workflow/poller'

describe Temporal::Workflow::Poller do
  let(:connection) { instance_double('Temporal::Connection::GRPC') }
  let(:namespace) { 'test-namespace' }
  let(:task_queue) { 'test-task-queue' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup') }
  let(:config) { Temporal::Configuration.new }
  let(:middleware_chain) { instance_double(Temporal::Middleware::Chain) }
  let(:middleware) { [] }
  let(:workflow_middleware_chain) { instance_double(Temporal::Middleware::Chain) }
  let(:workflow_middleware) { [] }
  let(:empty_middleware_chain) { instance_double(Temporal::Middleware::Chain) }
  let(:binary_checksum) { 'v1.0.0' }

  subject do
    described_class.new(
      namespace,
      task_queue,
      lookup,
      config,
      middleware,
      workflow_middleware,
      {
        binary_checksum: binary_checksum
      }
    )
  end

  before do
    allow(Temporal::Connection).to receive(:generate).and_return(connection)
    allow(Temporal::Middleware::Chain).to receive(:new).with(workflow_middleware).and_return(workflow_middleware_chain)
    allow(Temporal::Middleware::Chain).to receive(:new).with(middleware).and_return(middleware_chain)
    allow(Temporal::Middleware::Chain).to receive(:new).with([]).and_return(empty_middleware_chain)
    allow(Temporal.metrics).to receive(:timing)
    allow(Temporal.metrics).to receive(:increment)
  end

  describe '#start' do
    it 'polls for decision tasks' do
      allow(subject).to receive(:shutting_down?).and_return(false, false, true)
      allow(connection).to receive(:poll_workflow_task_queue).and_return(nil)

      subject.start

      # stop poller before inspecting
      subject.stop_polling; subject.wait

      expect(connection)
        .to have_received(:poll_workflow_task_queue)
        .with(namespace: namespace, task_queue: task_queue, binary_checksum: binary_checksum)
        .twice
    end

    it 'reports time since last poll' do
      allow(subject).to receive(:shutting_down?).and_return(false, false, true)
      allow(connection).to receive(:poll_workflow_task_queue).and_return(nil)

      subject.start

      # stop poller before inspecting
      subject.stop_polling; subject.wait

      expect(Temporal.metrics)
        .to have_received(:timing)
        .with(
          Temporal::MetricKeys::WORKFLOW_POLLER_TIME_SINCE_LAST_POLL,
          an_instance_of(Integer),
          namespace: namespace,
          task_queue: task_queue
        )
        .twice
    end

    it 'reports polling completed with received_task false' do
      allow(subject).to receive(:shutting_down?).and_return(false, false, true)
      allow(connection).to receive(:poll_workflow_task_queue).and_return(nil)

      subject.start

      # stop poller before inspecting
      subject.stop_polling; subject.wait

      expect(Temporal.metrics)
        .to have_received(:increment)
        .with(
          Temporal::MetricKeys::WORKFLOW_POLLER_POLL_COMPLETED,
          received_task: 'false',
          namespace: namespace,
          task_queue: task_queue
        )
        .twice
    end

    context 'when a workflow task is received' do
      let(:task_processor) do
        instance_double(Temporal::Workflow::TaskProcessor, process: nil)
      end
      let(:task) { Fabricate(:api_workflow_task) }

      before do
        allow(subject).to receive(:shutting_down?).and_return(false, true)
        allow(connection).to receive(:poll_workflow_task_queue).and_return(task)
        allow(Temporal::Workflow::TaskProcessor).to receive(:new).and_return(task_processor)
      end

      it 'uses TaskProcessor to process tasks' do
        subject.start

        # stop poller before inspecting
        subject.stop_polling; subject.wait

        expect(Temporal::Workflow::TaskProcessor)
          .to have_received(:new)
          .with(task, namespace, lookup, empty_middleware_chain, empty_middleware_chain, config, binary_checksum)
        expect(task_processor).to have_received(:process)
      end

      it 'reports polling completed with received_task true' do
        subject.start

        # stop poller before inspecting
        subject.stop_polling; subject.wait

        expect(Temporal.metrics)
          .to have_received(:increment)
          .with(
            Temporal::MetricKeys::WORKFLOW_POLLER_POLL_COMPLETED,
            received_task: 'true',
            namespace: namespace,
            task_queue: task_queue
          )
          .once
      end

      context 'with middleware configured' do
        class TestPollerMiddleware
          def initialize(_); end

          def call(_); end
        end

        let(:workflow_middleware) { [entry_1] }
        let(:middleware) { [entry_1, entry_2] }
        let(:entry_1) { Temporal::Middleware::Entry.new(TestPollerMiddleware, '1') }
        let(:entry_2) { Temporal::Middleware::Entry.new(TestPollerMiddleware, '2') }


        it 'initializes middleware chain and passes it down to TaskProcessor' do
          subject.start

          # stop poller before inspecting
          subject.stop_polling; subject.wait

          expect(Temporal::Middleware::Chain).to have_received(:new).with(middleware)
          expect(Temporal::Middleware::Chain).to have_received(:new).with(workflow_middleware)
          expect(Temporal::Workflow::TaskProcessor)
            .to have_received(:new)
            .with(task, namespace, lookup, middleware_chain, workflow_middleware_chain, config, binary_checksum)
        end
      end
    end

    context 'when connection is unable to poll' do
      before do
        allow(subject).to receive(:shutting_down?).and_return(false, true)
        allow(connection).to receive(:poll_workflow_task_queue).and_raise(StandardError)
        allow(subject).to receive(:sleep_before_retry).and_return(nil)
      end

      it 'logs' do
        allow(Temporal.logger).to receive(:error)

        subject.start

        # stop poller before inspecting
        subject.stop_polling; subject.wait

        expect(Temporal.logger)
          .to have_received(:error)
          .with(
            'Unable to poll Workflow task queue',
            namespace: namespace,
            task_queue: task_queue,
            error: '#<StandardError: StandardError>'
          )
      end

      it 'does not sleep' do
        subject.start

        # stop poller before inspecting
        subject.stop_polling; subject.wait

        expect(subject).to_not have_received(:sleep_before_retry)
      end
    end

    context 'when connection is unable to poll and poll_retry_seconds is set' do
      subject do
        described_class.new(
          namespace,
          task_queue,
          lookup,
          config,
          middleware,
          {
            binary_checksum: binary_checksum,
            poll_retry_seconds: 5
          }
        )
      end

      before do
        allow(subject).to receive(:shutting_down?).and_return(false, true)
        allow(connection).to receive(:poll_workflow_task_queue).and_raise(StandardError)
        allow(subject).to receive(:sleep_before_retry).and_return(nil)
      end

      it 'sleeps' do
        subject.start

        # stop poller before inspecting
        subject.stop_polling; subject.wait

        expect(subject).to have_received(:sleep_before_retry).with(5).once
      end
    end
  end
end
