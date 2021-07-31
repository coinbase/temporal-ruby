require 'temporal/workflow/poller'
require 'temporal/middleware/entry'

describe Temporal::Workflow::Poller do
  let(:client) { instance_double('Temporal::Client::GRPCClient') }
  let(:namespace) { 'test-namespace' }
  let(:task_queue) { 'test-task-queue' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup') }
  let(:middleware_chain) { instance_double(Temporal::Middleware::Chain) }
  let(:middleware) { [] }
  let(:busy_wait_delay) {0.01}

  subject { described_class.new(namespace, task_queue, lookup, middleware) }

  # poller will receive task times times, and nil thereafter.  
  # poller will be shut down after that
  def poll(poller, client, task, times: 1)
    polled_times = 0
    allow(client).to receive(:poll_workflow_task_queue) do
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
    allow(Temporal::Client).to receive(:generate).and_return(client)
    allow(Temporal::Middleware::Chain).to receive(:new).and_return(middleware_chain)
    allow(Temporal.metrics).to receive(:timing)
  end

  describe '#start' do
    it 'polls for workflow tasks' do
      subject.start
      times = poll(subject, client, nil, times: 2)
      expect(times).to be >=(2)
    end

    it 'reports time since last poll' do
      poll(subject, client, nil)

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
        poll(subject, client, task)

        expect(Temporal::Workflow::TaskProcessor)
          .to have_received(:new)
          .with(task, namespace, lookup, client, middleware_chain)
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
          poll(subject, client, task)

          expect(Temporal::Middleware::Chain).to have_received(:new).with(middleware)
          expect(Temporal::Workflow::TaskProcessor)
            .to have_received(:new)
            .with(task, namespace, lookup, client, middleware_chain)
        end
      end
    end

    context 'when client is unable to poll' do
      it 'logs' do
        allow(Temporal.logger).to receive(:error)

        polled = false
        allow(client).to receive(:poll_workflow_task_queue) do 
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
