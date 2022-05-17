require 'temporal/workflow/poller'
require 'temporal/middleware/entry'
require 'temporal/configuration'

describe Temporal::Workflow::Poller do
  let(:connection) { instance_double('Temporal::Connection::GRPC') }
  let(:namespace) { 'test-namespace' }
  let(:task_queue) { 'test-task-queue' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup') }
  let(:config) { Temporal::Configuration.new }
  let(:middleware_chain) { instance_double(Temporal::Middleware::Chain) }
  let(:middleware) { [] }
  let(:busy_wait_delay) {0.01}
  let(:binary_checksum) { 'v1.0.0' }

  subject do
    described_class.new(
      namespace,
      task_queue,
      lookup,
      config,
      middleware,
      {
        binary_checksum: binary_checksum
      }
    )
  end

  # poller will receive task times times, and nil thereafter.  
  # poller will be shut down after that
  def poll(poller, connection, task, times: 1)
    polled_times = 0
    allow(connection).to receive(:poll_workflow_task_queue) do
      polled_times += 1
      if polled_times <= times
        task
      else
        nil
      end
    end

    poller.start

    while polled_times < times
      sleep(busy_wait_delay)
    end
    # stop poller before inspecting
    poller.stop_polling; poller.wait
    polled_times
  end

  before do
    allow(Temporal::Connection).to receive(:generate).and_return(connection)
    allow(Temporal::Middleware::Chain).to receive(:new).and_return(middleware_chain)
    allow(Temporal.metrics).to receive(:timing)
  end

  describe '#start' do
    it 'polls for workflow tasks' do
      subject.start
      times = poll(subject, connection, nil, times: 2)
      expect(times).to be >=(2)
    end

    it 'reports time since last poll' do
      poll(subject, connection, nil)

      expect(Temporal.metrics)
        .to have_received(:timing)
        .with(
          'workflow_poller.time_since_last_poll',
          an_instance_of(Fixnum),
          namespace: namespace,
          task_queue: task_queue
        )
        .at_least(2).times
    end

    context 'when an decision task is received' do
      let(:task_processor) do
        instance_double(Temporal::Workflow::TaskProcessor, process: nil)
      end
      let(:task) { Fabricate(:api_workflow_task) }

      before do
        allow(Temporal::Workflow::TaskProcessor).to receive(:new).and_return(task_processor)
      end

      it 'uses TaskProcessor to process tasks' do
        poll(subject, connection, task)

        expect(Temporal::Workflow::TaskProcessor)
          .to have_received(:new)
          .with(task, namespace, lookup, middleware_chain, config, binary_checksum)
        expect(task_processor).to have_received(:process)
      end

      context 'with middleware configured' do
        class TestPollerMiddleware
          def initialize(_); end
          def call(_); end
        end

        let(:middleware) { [entry_1, entry_2] }
        let(:entry_1) { Temporal::Middleware::Entry.new(TestPollerMiddleware, '1') }
        let(:entry_2) { Temporal::Middleware::Entry.new(TestPollerMiddleware, '2') }

        it 'initializes middleware chain and passes it down to TaskProcessor' do
          poll(subject, connection, task)

          expect(Temporal::Middleware::Chain).to have_received(:new).with(middleware)
          expect(Temporal::Workflow::TaskProcessor)
            .to have_received(:new)
            .with(task, namespace, lookup, middleware_chain, config, binary_checksum)
        end
      end
    end

    context 'when connection is unable to poll' do
      it 'logs' do
        allow(Temporal.logger).to receive(:error)

        polled = false
        allow(connection).to receive(:poll_workflow_task_queue) do 
          if !polled
            polled = true
            raise StandardError
          end
        end

        subject.start
        while !polled 
          sleep(busy_wait_delay)
        end
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
    end
  end
end
