require 'temporal/activity/poller'
require 'temporal/configuration'
require 'temporal/metric_keys'
require 'temporal/middleware/entry'

describe Temporal::Activity::Poller do
  let(:connection) { instance_double('Temporal::Connection::GRPC', cancel_polling_request: nil) }
  let(:namespace) { 'test-namespace' }
  let(:task_queue) { 'test-task-queue' }
  let(:lookup) { instance_double('Temporal::ExecutableLookup') }
  let(:thread_pool) do
    instance_double(Temporal::ThreadPool, wait_for_available_threads: nil, shutdown: nil)
  end
  let(:heartbeat_thread_pool) do
    instance_double(Temporal::ScheduledThreadPool, shutdown: nil)
  end
  let(:config) { Temporal::Configuration.new }
  let(:middleware_chain) { instance_double(Temporal::Middleware::Chain) }
  let(:middleware) { [] }
  let(:busy_wait_delay) {0.01}

  subject { described_class.new(namespace, task_queue, lookup, config, middleware) }

  before do
    allow(Temporal::Connection).to receive(:generate).and_return(connection)
    allow(Temporal::ThreadPool).to receive(:new).and_return(thread_pool)
    allow(Temporal::ScheduledThreadPool).to receive(:new).and_return(heartbeat_thread_pool)
    allow(Temporal::Middleware::Chain).to receive(:new).and_return(middleware_chain)
    allow(Temporal.metrics).to receive(:timing)
    allow(Temporal.metrics).to receive(:increment)
  end

  # poller will receive task times times, and nil thereafter.
  # poller will be shut down after that
  def poll(task, times: 1)
    polled_times = 0
    allow(connection).to receive(:poll_activity_task_queue) do
      polled_times += 1
      if polled_times <= times
        task
      else
        nil
      end
    end

    subject.start

    while polled_times < times
      sleep(busy_wait_delay)
    end
    # stop poller before inspecting
    subject.stop_polling; subject.wait
    polled_times
  end

  describe '#start' do
    it 'measures time between polls' do
      # if it doesn't poll, this test will loop forever
      times = poll(nil, times: 2)
      expect(times).to be >= 2
    end

    it 'reports time since last poll' do
      poll(nil, times: 2)

      expect(Temporal.metrics)
        .to have_received(:timing)
        .with(
          Temporal::MetricKeys::ACTIVITY_POLLER_TIME_SINCE_LAST_POLL,
          an_instance_of(Integer),
          namespace: namespace,
          task_queue: task_queue
        )
        .at_least(:twice)
    end

    it 'reports polling completed with received_task false' do
      poll(nil, times: 2)

      expect(Temporal.metrics)
        .to have_received(:increment)
        .with(
          Temporal::MetricKeys::ACTIVITY_POLLER_POLL_COMPLETED,
          received_task: 'false',
          namespace: namespace,
          task_queue: task_queue
        )
        .at_least(:twice)
    end

    context 'when an activity task is received' do
      let(:task_processor) { instance_double(Temporal::Activity::TaskProcessor, process: nil) }
      let(:task) { Fabricate(:api_activity_task) }

      before do
        allow(Temporal::Activity::TaskProcessor).to receive(:new).and_return(task_processor)
        allow(thread_pool).to receive(:schedule).and_yield
      end

      it 'schedules task processing using a ThreadPool' do
        poll(task)

        expect(thread_pool).to have_received(:schedule)
      end

      it 'uses TaskProcessor to process tasks' do
        poll(task)

        expect(Temporal::Activity::TaskProcessor)
          .to have_received(:new)
          .with(task, namespace, lookup, middleware_chain, config, heartbeat_thread_pool)
        expect(task_processor).to have_received(:process)
      end

      it 'reports polling completed with received_task true' do
        poll(task)

        expect(Temporal.metrics)
          .to have_received(:increment)
          .with(
            Temporal::MetricKeys::ACTIVITY_POLLER_POLL_COMPLETED,
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

        let(:middleware) { [entry_1, entry_2] }
        let(:entry_1) { Temporal::Middleware::Entry.new(TestPollerMiddleware, '1') }
        let(:entry_2) { Temporal::Middleware::Entry.new(TestPollerMiddleware, '2') }

        it 'initializes middleware chain and passes it down to TaskProcessor' do
          poll(task)

          expect(Temporal::Middleware::Chain).to have_received(:new).with(middleware)
          expect(Temporal::Activity::TaskProcessor)
            .to have_received(:new)
            .with(task, namespace, lookup, middleware_chain, config, heartbeat_thread_pool)
        end
      end
    end

    context 'when connection is unable to poll' do
      before do
        allow(subject).to receive(:sleep).and_return(nil)
      end

      it 'logs' do
        allow(Temporal.logger).to receive(:error)

        polled = false
        allow(connection).to receive(:poll_activity_task_queue) do
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
          .with('Unable to poll activity task queue', { namespace: 'test-namespace', task_queue: 'test-task-queue', error: '#<StandardError: StandardError>' })
      end

      it 'does not sleep' do
        polled = false
        allow(connection).to receive(:poll_activity_task_queue) do
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

        expect(subject).to have_received(:sleep).with(0).once
      end
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
          poll_retry_seconds: 5
        }
      )
    end

    before do
      allow(subject).to receive(:sleep).and_return(nil)
    end

    it 'sleeps' do
      polled = false
      allow(connection).to receive(:poll_activity_task_queue) do
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

      expect(subject).to have_received(:sleep).with(5).once
    end
  end

  describe '#cancel_pending_requests' do
    before { subject.start }
    after { subject.wait }

    it 'tells connection to cancel polling requests' do
      subject.stop_polling
      subject.cancel_pending_requests

      expect(connection).to have_received(:cancel_polling_request)
    end
  end

  describe '#wait' do
    before do
      subject.start
      subject.stop_polling
    end

    it 'shuts down the thread poll' do
      subject.wait

      expect(thread_pool).to have_received(:shutdown)
    end
  end
end
