require 'cadence/worker'
require 'cadence/workflow'
require 'cadence/activity'

describe Cadence::Worker do
  class TestWorkerWorkflow < Cadence::Workflow
    domain 'default-domain'
    task_list 'default-task-list'
  end

  class TestWorkerActivity < Cadence::Activity
    domain 'default-domain'
    task_list 'default-task-list'
  end

  class TestWorkerDecisionMiddleware
    def call(_); end
  end

  class TestWorkerActivityMiddleware
    def call(_); end
  end

  class TestWorkerActivity < Cadence::Activity
    domain 'default-domain'
    task_list 'default-task-list'
  end

  THREAD_SYNC_DELAY = 0.01

  before do
    # Make sure we don't actually sleep in tests
    allow(subject).to receive(:sleep).and_return(nil)
  end

  describe '#register_workflow' do
    let(:lookup) { instance_double(Cadence::ExecutableLookup, add: nil) }
    let(:workflow_keys) { subject.send(:workflows).keys }

    before { expect(Cadence::ExecutableLookup).to receive(:new).and_return(lookup) }

    it 'registers a workflow based on the default config options' do
      subject.register_workflow(TestWorkerWorkflow)

      expect(lookup).to have_received(:add).with('TestWorkerWorkflow', TestWorkerWorkflow)
      expect(workflow_keys).to include(['default-domain', 'default-task-list'])
    end

    it 'registers a workflow with provided config options' do
      subject.register_workflow(
        TestWorkerWorkflow,
        name: 'test-workflow',
        domain: 'test-domain',
        task_list: 'test-task-list'
      )

      expect(lookup).to have_received(:add).with('test-workflow', TestWorkerWorkflow)
      expect(workflow_keys).to include(['test-domain', 'test-task-list'])
    end
  end

  describe '#register_activity' do
    let(:lookup) { instance_double(Cadence::ExecutableLookup, add: nil) }
    let(:activity_keys) { subject.send(:activities).keys }

    before { expect(Cadence::ExecutableLookup).to receive(:new).and_return(lookup) }

    it 'registers an activity based on the default config options' do
      subject.register_activity(TestWorkerActivity)

      expect(lookup).to have_received(:add).with('TestWorkerActivity', TestWorkerActivity)
      expect(activity_keys).to include(['default-domain', 'default-task-list'])
    end

    it 'registers an activity with provided config options' do
      subject.register_activity(
        TestWorkerActivity,
        name: 'test-activity',
        domain: 'test-domain',
        task_list: 'test-task-list'
      )

      expect(lookup).to have_received(:add).with('test-activity', TestWorkerActivity)
      expect(activity_keys).to include(['test-domain', 'test-task-list'])
    end
  end

  describe '#add_decision_middleware' do
    let(:middleware) { subject.send(:decision_middleware) }

    it 'adds middleware entry to the list of middlewares' do
      subject.add_decision_middleware(TestWorkerDecisionMiddleware)
      subject.add_decision_middleware(TestWorkerDecisionMiddleware, 'arg1', 'arg2')

      expect(middleware.size).to eq(2)

      expect(middleware[0]).to be_an_instance_of(Cadence::Middleware::Entry)
      expect(middleware[0].klass).to eq(TestWorkerDecisionMiddleware)
      expect(middleware[0].args).to eq([])

      expect(middleware[1]).to be_an_instance_of(Cadence::Middleware::Entry)
      expect(middleware[1].klass).to eq(TestWorkerDecisionMiddleware)
      expect(middleware[1].args).to eq(['arg1', 'arg2'])
    end
  end

  describe '#add_activity_middleware' do
    let(:middleware) { subject.send(:activity_middleware) }

    it 'adds middleware entry to the list of middlewares' do
      subject.add_activity_middleware(TestWorkerActivityMiddleware)
      subject.add_activity_middleware(TestWorkerActivityMiddleware, 'arg1', 'arg2')

      expect(middleware.size).to eq(2)

      expect(middleware[0]).to be_an_instance_of(Cadence::Middleware::Entry)
      expect(middleware[0].klass).to eq(TestWorkerActivityMiddleware)
      expect(middleware[0].args).to eq([])

      expect(middleware[1]).to be_an_instance_of(Cadence::Middleware::Entry)
      expect(middleware[1].klass).to eq(TestWorkerActivityMiddleware)
      expect(middleware[1].args).to eq(['arg1', 'arg2'])
    end
  end

  describe '#start' do
    let(:workflow_poller_1) { instance_double(Cadence::Workflow::Poller, start: nil) }
    let(:workflow_poller_2) { instance_double(Cadence::Workflow::Poller, start: nil) }
    let(:activity_poller_1) { instance_double(Cadence::Activity::Poller, start: nil) }
    let(:activity_poller_2) { instance_double(Cadence::Activity::Poller, start: nil) }

    it 'starts a poller for each domain/task list combination' do
      allow(subject).to receive(:shutting_down?).and_return(true)

      allow(Cadence::Workflow::Poller)
        .to receive(:new)
        .with('default-domain', 'default-task-list', an_instance_of(Cadence::ExecutableLookup), [])
        .and_return(workflow_poller_1)

      allow(Cadence::Workflow::Poller)
        .to receive(:new)
        .with('other-domain', 'default-task-list', an_instance_of(Cadence::ExecutableLookup), [])
        .and_return(workflow_poller_2)

      allow(Cadence::Activity::Poller)
        .to receive(:new)
        .with('default-domain', 'default-task-list', an_instance_of(Cadence::ExecutableLookup), [])
        .and_return(activity_poller_1)

      allow(Cadence::Activity::Poller)
        .to receive(:new)
        .with('default-domain', 'other-task-list', an_instance_of(Cadence::ExecutableLookup), [])
        .and_return(activity_poller_2)

      subject.register_workflow(TestWorkerWorkflow)
      subject.register_workflow(TestWorkerWorkflow, domain: 'other-domain')
      subject.register_activity(TestWorkerActivity)
      subject.register_activity(TestWorkerActivity, task_list: 'other-task-list')

      subject.start

      expect(workflow_poller_1).to have_received(:start)
      expect(workflow_poller_2).to have_received(:start)
      expect(activity_poller_1).to have_received(:start)
      expect(activity_poller_2).to have_received(:start)
    end

    context 'when middleware is configured' do
      let(:entry_1) { instance_double(Cadence::Middleware::Entry) }
      let(:entry_2) { instance_double(Cadence::Middleware::Entry) }

      before do
        allow(Cadence::Middleware::Entry)
          .to receive(:new)
          .with(TestWorkerDecisionMiddleware, [])
          .and_return(entry_1)

        allow(Cadence::Middleware::Entry)
          .to receive(:new)
          .with(TestWorkerActivityMiddleware, [])
          .and_return(entry_2)

        subject.add_decision_middleware(TestWorkerDecisionMiddleware)
        subject.add_activity_middleware(TestWorkerActivityMiddleware)
      end

      it 'starts pollers with correct middleware' do
        allow(subject).to receive(:shutting_down?).and_return(true)

        allow(Cadence::Workflow::Poller)
          .to receive(:new)
          .with('default-domain', 'default-task-list', an_instance_of(Cadence::ExecutableLookup), [entry_1])
          .and_return(workflow_poller_1)

        allow(Cadence::Activity::Poller)
          .to receive(:new)
          .with('default-domain', 'default-task-list', an_instance_of(Cadence::ExecutableLookup), [entry_2])
          .and_return(activity_poller_1)

        subject.register_workflow(TestWorkerWorkflow)
        subject.register_activity(TestWorkerActivity)

        subject.start

        expect(workflow_poller_1).to have_received(:start)
        expect(activity_poller_1).to have_received(:start)
      end
    end

    it 'sleeps while waiting for the shutdown' do
      allow(subject).to receive(:shutting_down?).and_return(false, false, false, true)
      allow(subject).to receive(:sleep).and_return(nil)

      subject.start

      expect(subject).to have_received(:sleep).with(1).exactly(3).times
    end

    describe 'signal handling' do
      before do
        @thread = Thread.new { subject.start }
        sleep THREAD_SYNC_DELAY # give worker time to start
      end

      around do |example|
        # Trick RSpec into not shutting itself down on TERM signal
        old_term_handler = Signal.trap('TERM', 'SYSTEM_DEFAULT')
        old_int_handler = Signal.trap('INT', 'SYSTEM_DEFAULT')

        example.run

        # Restore the original signal handling behaviour
        Signal.trap('TERM', old_term_handler)
        Signal.trap('INT', old_int_handler)
      end

      it 'traps TERM signal' do
        Process.kill('TERM', 0)
        sleep THREAD_SYNC_DELAY

        expect(@thread).not_to be_alive
      end

      it 'traps INT signal' do
        Process.kill('INT', 0)
        sleep THREAD_SYNC_DELAY

        expect(@thread).not_to be_alive
      end
    end
  end

  describe '#stop' do
    let(:workflow_poller) { instance_double(Cadence::Workflow::Poller, start: nil, stop: nil, wait: nil) }
    let(:activity_poller) { instance_double(Cadence::Activity::Poller, start: nil, stop: nil, wait: nil) }

    before do
      allow(Cadence::Workflow::Poller).to receive(:new).and_return(workflow_poller)
      allow(Cadence::Activity::Poller).to receive(:new).and_return(activity_poller)

      subject.register_workflow(TestWorkerWorkflow)
      subject.register_activity(TestWorkerActivity)

      @thread = Thread.new { subject.start }
      sleep THREAD_SYNC_DELAY # allow worker to start
    end

    it 'stops the pollers' do
      subject.stop

      sleep THREAD_SYNC_DELAY # wait for the worker to stop

      expect(@thread).not_to be_alive
      expect(workflow_poller).to have_received(:stop)
      expect(activity_poller).to have_received(:stop)
    end

    it 'waits for the pollers to stop' do
      subject.stop

      sleep THREAD_SYNC_DELAY # wait for worker to stop

      expect(@thread).not_to be_alive
      expect(workflow_poller).to have_received(:wait)
      expect(activity_poller).to have_received(:wait)
    end
  end
end
