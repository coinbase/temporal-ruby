require 'cadence/activity/poller'
require 'cadence/middleware/entry'

describe Cadence::Activity::Poller do
  let(:client) { instance_double('Cadence::Client::ThriftClient') }
  let(:domain) { 'test-domain' }
  let(:task_list) { 'test-task-list' }
  let(:lookup) { instance_double('Cadence::ExecutableLookup') }
  let(:thread_pool) { instance_double(Cadence::ThreadPool, wait_for_available_threads: nil) }
  let(:middleware_chain) { instance_double(Cadence::Middleware::Chain) }
  let(:middleware) { [] }

  subject { described_class.new(domain, task_list, lookup, middleware) }

  before do
    allow(Cadence::Client).to receive(:generate).and_return(client)
    allow(Cadence::ThreadPool).to receive(:new).and_return(thread_pool)
    allow(Cadence::Middleware::Chain).to receive(:new).and_return(middleware_chain)
  end

  describe '#start' do
    it 'polls for activity tasks' do
      allow(subject).to receive(:shutting_down?).and_return(false, false, true)
      allow(client).to receive(:poll_for_activity_task).and_return(nil)

      subject.start

      # stop poller before inspecting
      subject.stop; subject.wait

      expect(client)
        .to have_received(:poll_for_activity_task)
        .with(domain: domain, task_list: task_list)
        .twice
    end

    context 'when an activity task is received' do
      let(:task_processor) { instance_double(Cadence::Activity::TaskProcessor, process: nil) }
      let(:task) { Fabricate(:activity_task) }

      before do
        allow(subject).to receive(:shutting_down?).and_return(false, true)
        allow(client).to receive(:poll_for_activity_task).and_return(task)
        allow(Cadence::Activity::TaskProcessor).to receive(:new).and_return(task_processor)
        allow(thread_pool).to receive(:schedule).and_yield
      end

      it 'schedules task processing using a ThreadPool' do
        subject.start

        # stop poller before inspecting
        subject.stop; subject.wait

        expect(thread_pool).to have_received(:schedule)
      end

      it 'uses TaskProcessor to process tasks' do
        subject.start

        # stop poller before inspecting
        subject.stop; subject.wait

        expect(Cadence::Activity::TaskProcessor)
          .to have_received(:new)
          .with(task, lookup, client, middleware_chain)
        expect(task_processor).to have_received(:process)
      end

      context 'with middleware configured' do
        class TestPollerMiddleware
          def initialize(_); end
          def call(_); end
        end

        let(:middleware) { [entry_1, entry_2] }
        let(:entry_1) { Cadence::Middleware::Entry.new(TestPollerMiddleware, '1') }
        let(:entry_2) { Cadence::Middleware::Entry.new(TestPollerMiddleware, '2') }

        it 'initializes middleware chain and passes it down to TaskProcessor' do
          subject.start

          # stop poller before inspecting
          subject.stop; subject.wait

          expect(Cadence::Middleware::Chain).to have_received(:new).with(middleware)
          expect(Cadence::Activity::TaskProcessor)
            .to have_received(:new)
            .with(task, lookup, client, middleware_chain)
        end
      end
    end

    context 'when client is unable to poll' do
      before do
        allow(subject).to receive(:shutting_down?).and_return(false, true)
        allow(client).to receive(:poll_for_activity_task).and_raise(StandardError)
      end

      it 'logs' do
        allow(Cadence.logger).to receive(:error)

        subject.start

        # stop poller before inspecting
        subject.stop; subject.wait

        expect(Cadence.logger)
          .to have_received(:error)
          .with('Unable to poll for an activity task: #<StandardError: StandardError>')
      end
    end
  end
end
