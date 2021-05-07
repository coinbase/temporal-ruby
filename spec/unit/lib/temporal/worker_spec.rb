require 'temporal/worker'
require 'temporal/workflow'
require 'temporal/activity'

describe Temporal::Worker do
  class TestWorkerWorkflow < Temporal::Workflow
    namespace 'default-namespace'
    task_queue 'default-task-queue'
  end

  class TestWorkerActivity < Temporal::Activity
    namespace 'default-namespace'
    task_queue 'default-task-queue'
  end

  class TestWorkerWorkflowTaskMiddleware
    def call(_); end
  end

  class TestWorkerActivityMiddleware
    def call(_); end
  end

  class TestWorkerActivity < Temporal::Activity
    namespace 'default-namespace'
    task_queue 'default-task-queue'
  end

  THREAD_SYNC_DELAY = 0.01

  before do
    # Make sure we don't actually sleep in tests
    allow(subject).to receive(:sleep).and_return(nil)
  end

  describe '#register_workflow' do
    let(:lookup) { instance_double(Temporal::ExecutableLookup, add: nil) }
    let(:workflow_keys) { subject.send(:workflows).keys }

    before { expect(Temporal::ExecutableLookup).to receive(:new).and_return(lookup) }

    it 'registers a workflow based on the default config options' do
      subject.register_workflow(TestWorkerWorkflow)

      expect(lookup).to have_received(:add).with('TestWorkerWorkflow', TestWorkerWorkflow)
      expect(workflow_keys).to include(['default-namespace', 'default-task-queue'])
    end

    it 'registers a workflow with provided config options' do
      subject.register_workflow(
        TestWorkerWorkflow,
        name: 'test-workflow',
        namespace: 'test-namespace',
        task_queue: 'test-task-queue'
      )

      expect(lookup).to have_received(:add).with('test-workflow', TestWorkerWorkflow)
      expect(workflow_keys).to include(['test-namespace', 'test-task-queue'])
    end
  end

  describe '#register_activity' do
    let(:lookup) { instance_double(Temporal::ExecutableLookup, add: nil) }
    let(:activity_keys) { subject.send(:activities).keys }

    before { expect(Temporal::ExecutableLookup).to receive(:new).and_return(lookup) }

    it 'registers an activity based on the default config options' do
      subject.register_activity(TestWorkerActivity)

      expect(lookup).to have_received(:add).with('TestWorkerActivity', TestWorkerActivity)
      expect(activity_keys).to include(['default-namespace', 'default-task-queue'])
    end

    it 'registers an activity with provided config options' do
      subject.register_activity(
        TestWorkerActivity,
        name: 'test-activity',
        namespace: 'test-namespace',
        task_queue: 'test-task-queue'
      )

      expect(lookup).to have_received(:add).with('test-activity', TestWorkerActivity)
      expect(activity_keys).to include(['test-namespace', 'test-task-queue'])
    end
  end

  describe '#add_workflow_task_middleware' do
    let(:middleware) { subject.send(:workflow_task_middleware) }

    it 'adds middleware entry to the list of middlewares' do
      subject.add_workflow_task_middleware(TestWorkerWorkflowTaskMiddleware)
      subject.add_workflow_task_middleware(TestWorkerWorkflowTaskMiddleware, 'arg1', 'arg2')

      expect(middleware.size).to eq(2)

      expect(middleware[0]).to be_an_instance_of(Temporal::Middleware::Entry)
      expect(middleware[0].klass).to eq(TestWorkerWorkflowTaskMiddleware)
      expect(middleware[0].args).to eq([])

      expect(middleware[1]).to be_an_instance_of(Temporal::Middleware::Entry)
      expect(middleware[1].klass).to eq(TestWorkerWorkflowTaskMiddleware)
      expect(middleware[1].args).to eq(['arg1', 'arg2'])
    end
  end

  describe '#add_activity_middleware' do
    let(:middleware) { subject.send(:activity_middleware) }

    it 'adds middleware entry to the list of middlewares' do
      subject.add_activity_middleware(TestWorkerActivityMiddleware)
      subject.add_activity_middleware(TestWorkerActivityMiddleware, 'arg1', 'arg2')

      expect(middleware.size).to eq(2)

      expect(middleware[0]).to be_an_instance_of(Temporal::Middleware::Entry)
      expect(middleware[0].klass).to eq(TestWorkerActivityMiddleware)
      expect(middleware[0].args).to eq([])

      expect(middleware[1]).to be_an_instance_of(Temporal::Middleware::Entry)
      expect(middleware[1].klass).to eq(TestWorkerActivityMiddleware)
      expect(middleware[1].args).to eq(['arg1', 'arg2'])
    end
  end

  describe '#start' do
    let(:workflow_poller_1) { instance_double(Temporal::Workflow::Poller, start: nil) }
    let(:workflow_poller_2) { instance_double(Temporal::Workflow::Poller, start: nil) }
    let(:activity_poller_1) { instance_double(Temporal::Activity::Poller, start: nil) }
    let(:activity_poller_2) { instance_double(Temporal::Activity::Poller, start: nil) }

    it 'starts a poller for each namespace/task list combination' do
      allow(subject).to receive(:shutting_down?).and_return(true)

      allow(Temporal::Workflow::Poller)
        .to receive(:new)
        .with(
          'default-namespace',
          'default-task-queue',
          an_instance_of(Temporal::ExecutableLookup),
          [],
          thread_pool_size: 10
        )
        .and_return(workflow_poller_1)

      allow(Temporal::Workflow::Poller)
        .to receive(:new)
        .with(
          'other-namespace',
          'default-task-queue',
          an_instance_of(Temporal::ExecutableLookup),
          [],
          thread_pool_size: 10
        )
        .and_return(workflow_poller_2)

      allow(Temporal::Activity::Poller)
        .to receive(:new)
        .with(
          'default-namespace',
          'default-task-queue',
          an_instance_of(Temporal::ExecutableLookup),
          [],
          thread_pool_size: 20
        )
        .and_return(activity_poller_1)

      allow(Temporal::Activity::Poller)
        .to receive(:new)
        .with(
          'default-namespace',
          'other-task-queue',
          an_instance_of(Temporal::ExecutableLookup),
          [],
          thread_pool_size: 20
        )
        .and_return(activity_poller_2)

      subject.register_workflow(TestWorkerWorkflow)
      subject.register_workflow(TestWorkerWorkflow, namespace: 'other-namespace')
      subject.register_activity(TestWorkerActivity)
      subject.register_activity(TestWorkerActivity, task_queue: 'other-task-queue')

      subject.start

      expect(workflow_poller_1).to have_received(:start)
      expect(workflow_poller_2).to have_received(:start)
      expect(activity_poller_1).to have_received(:start)
      expect(activity_poller_2).to have_received(:start)
    end

    it 'can have an activity poller with a different thread pool size' do
      activity_poller = instance_double(Temporal::Activity::Poller, start: nil)
      expect(Temporal::Activity::Poller)
        .to receive(:new)
        .with('default-namespace', 'default-task-queue', an_instance_of(Temporal::ExecutableLookup), [], {thread_pool_size: 10})
        .and_return(activity_poller)

      worker = Temporal::Worker.new(activity_thread_pool_size: 10)
      allow(worker).to receive(:shutting_down?).and_return(true)
      worker.register_workflow(TestWorkerWorkflow)
      worker.register_activity(TestWorkerActivity)

      worker.start

      expect(activity_poller).to have_received(:start)

    end

    context 'when middleware is configured' do
      let(:entry_1) { instance_double(Temporal::Middleware::Entry) }
      let(:entry_2) { instance_double(Temporal::Middleware::Entry) }

      before do
        allow(Temporal::Middleware::Entry)
          .to receive(:new)
          .with(TestWorkerWorkflowTaskMiddleware, [])
          .and_return(entry_1)

        allow(Temporal::Middleware::Entry)
          .to receive(:new)
          .with(TestWorkerActivityMiddleware, [])
          .and_return(entry_2)

        subject.add_workflow_task_middleware(TestWorkerWorkflowTaskMiddleware)
        subject.add_activity_middleware(TestWorkerActivityMiddleware)
      end

      it 'starts pollers with correct middleware' do
        allow(subject).to receive(:shutting_down?).and_return(true)

        allow(Temporal::Workflow::Poller)
          .to receive(:new)
          .with(
            'default-namespace',
            'default-task-queue',
            an_instance_of(Temporal::ExecutableLookup),
            [entry_1],
            thread_pool_size: 10
          )
          .and_return(workflow_poller_1)

        allow(Temporal::Activity::Poller)
          .to receive(:new)
          .with(
            'default-namespace',
            'default-task-queue',
            an_instance_of(Temporal::ExecutableLookup),
            [entry_2],
            thread_pool_size: 20
          )
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
    let(:workflow_poller) do
      instance_double(
        Temporal::Workflow::Poller,
        start: nil,
        stop_polling: nil,
        wait: nil,
        cancel_pending_requests: nil
      )
    end
    let(:activity_poller) do
      instance_double(
        Temporal::Activity::Poller,
        start: nil,
        stop_polling: nil,
        wait: nil,
        cancel_pending_requests: nil
      )
    end

    before do
      allow(Temporal::Workflow::Poller).to receive(:new).and_return(workflow_poller)
      allow(Temporal::Activity::Poller).to receive(:new).and_return(activity_poller)

      subject.register_workflow(TestWorkerWorkflow)
      subject.register_activity(TestWorkerActivity)

      @thread = Thread.new { subject.start }
      sleep THREAD_SYNC_DELAY # allow worker to start
    end

    it 'stops the pollers and cancels pending requests' do
      subject.stop

      sleep THREAD_SYNC_DELAY # wait for the worker to stop

      expect(@thread).not_to be_alive
      expect(workflow_poller).to have_received(:stop_polling)
      expect(workflow_poller).to have_received(:cancel_pending_requests)
      expect(activity_poller).to have_received(:stop_polling)
      expect(activity_poller).to have_received(:cancel_pending_requests)
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
