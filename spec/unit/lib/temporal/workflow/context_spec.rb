require 'temporal/activity'
require 'temporal/workflow'
require 'temporal/workflow/context'
require 'temporal/workflow/dispatcher'
require 'temporal/workflow/future'
require 'temporal/workflow/query_registry'
require 'temporal/workflow/stack_trace_tracker'
require 'temporal/metadata/workflow'
require 'time'

class MyTestWorkflow < Temporal::Workflow; end
class MyTestActivity < Temporal::Activity
  RETURN_VALUE = 'this-is-a-return-value'.freeze

  def execute
    RETURN_VALUE
  end
end

describe Temporal::Workflow::Context do
  let(:state_manager) { instance_double('Temporal::Workflow::StateManager') }
  let(:dispatcher) { Temporal::Workflow::Dispatcher.new }
  let(:query_registry) do
    double = instance_double('Temporal::Workflow::QueryRegistry')
    allow(double).to receive(:register)
    double
  end
  let(:metadata_hash) { Fabricate(:workflow_metadata).to_h }
  let(:metadata) { Temporal::Metadata::Workflow.new(**metadata_hash) }
  let(:config) { Temporal.configuration }

  let(:workflow_context) do
    Temporal::Workflow::Context.new(
      state_manager,
      dispatcher,
      MyTestWorkflow,
      metadata,
      config,
      query_registry,
      track_stack_trace
    )
  end
  let(:child_workflow_execution) { Fabricate(:api_workflow_execution) }
  let(:track_stack_trace) { false }

  describe '#on_query' do
    let(:handler) { Proc.new {} }

    it 'registers a query with the query registry' do
      workflow_context.on_query('test-query', &handler)

      expect(query_registry).to have_received(:register).with('test-query') do |&block|
        expect(block).to eq(handler)
      end
    end

    it 'automatically registers stack trace query' do
      expect(workflow_context).to_not be(nil) # ensure constructor is called
      expect(query_registry).to have_received(:register)
        .with(Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME)
    end

    context 'stack trace' do
      let(:track_stack_trace) { true }
      let(:query_registry) { Temporal::Workflow::QueryRegistry.new }

      it 'cleared to start' do
        expect(workflow_context).to_not be(nil) # ensure constructor is called
        stack_trace = query_registry.handle(Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME)
        expect(stack_trace).to eq("Fiber count: 0\n")
      end
    end
  end

  describe '#execute_activity' do
    context "with header propagation" do
      class TestHeaderPropagator
        def inject!(header)
          header['test'] = 'asdf'
        end
      end

      it 'propagates the header' do
        config.add_header_propagator(TestHeaderPropagator)
        expect(state_manager).to receive(:schedule).with(Temporal::Workflow::Command::ScheduleActivity.new(
          activity_id: nil,
          activity_type: 'MyTestActivity',
          input: [],
          task_queue: 'default-task-queue',
          retry_policy: nil,
          timeouts: {execution: 315360000, run: 315360000, task: 10, schedule_to_close: nil, schedule_to_start: nil, start_to_close: 30, heartbeat: nil, default_heartbeat_throttle_interval: 30, max_heartbeat_throttle_interval: 60},
          headers: { 'test' => 'asdf' }
        ))
        allow(dispatcher).to receive(:register_handler)
        workflow_context.execute_activity(MyTestActivity)
      end
    end
  end

  describe '#execute_local_activity' do
    it 'executes and schedules command' do
      expect(state_manager).to receive(:next_side_effect)
      expect(state_manager).to receive(:schedule).with(
        Temporal::Workflow::Command::RecordMarker.new(
          name: 'SIDE_EFFECT',
          details: MyTestActivity::RETURN_VALUE
        )
      )
      return_value = workflow_context.execute_local_activity(MyTestActivity)
      expect(return_value).to eq(MyTestActivity::RETURN_VALUE)
    end
  end

  describe '#execute_workflow' do
    it 'returns the correct futures when starting a child workflow' do
      allow(state_manager).to receive(:schedule)
      allow(dispatcher).to receive(:register_handler)

      result = workflow_context.execute_workflow(MyTestWorkflow)
      expect(result).to be_instance_of(Temporal::Workflow::ChildWorkflowFuture)
      expect(result.child_workflow_execution_future).to be_instance_of(Temporal::Workflow::Future)
    end

    it 'futures behave as expected when events are successful' do
      started_proc = nil
      completed_proc = nil

      allow(state_manager).to receive(:schedule)
      allow(dispatcher).to receive(:register_handler) do |target, event_name, &handler|
        case event_name
        when 'started'
          started_proc = handler
        when 'completed'
          completed_proc = handler
        end
      end

      child_workflow_future = workflow_context.execute_workflow(MyTestWorkflow)

      # expect all futures to be false as nothing has happened
      expect(child_workflow_future.finished?).to be false
      expect(child_workflow_future.child_workflow_execution_future.finished?).to be false

      # dispatch the start event and check if the child workflow execution changes to true
      started_proc.call(child_workflow_execution)
      expect(child_workflow_future.finished?).to be false
      expect(child_workflow_future.child_workflow_execution_future.finished?).to be true
      expect(child_workflow_future.child_workflow_execution_future.get).to be_instance_of(Temporalio::Api::Common::V1::WorkflowExecution)

      # complete the workflow via dispatch and check if the child workflow future is finished
      completed_proc.call('finished result')
      expect(child_workflow_future.finished?).to be true
      expect(child_workflow_future.child_workflow_execution_future.finished?).to be true
    end

    it 'futures behave as expected when child workflow fails' do
      started_proc = nil
      failed_proc = nil

      allow(state_manager).to receive(:schedule)
      allow(dispatcher).to receive(:register_handler) do |target, event_name, &handler|
        case event_name
        when 'started'
          started_proc = handler
        when 'failed'
          failed_proc = handler
        end
      end

      child_workflow_future = workflow_context.execute_workflow(MyTestWorkflow)

      # expect all futures to be false as nothing has happened
      expect(child_workflow_future.finished?).to be false
      expect(child_workflow_future.child_workflow_execution_future.finished?).to be false

      started_proc.call(child_workflow_execution)

      # dispatch the failed event and check the child_workflow_future failed but the child_workflow_execution_future finished
      failed_proc.call(Temporal::Workflow::Errors.generate_error_for_child_workflow_start("failed to start", "random-workflow-id"))
      expect(child_workflow_future.failed?).to be true
      expect(child_workflow_future.child_workflow_execution_future.failed?).to be false
    end

    it 'futures behave as expected when child execution workflow fails to start' do
      failed_proc = nil

      allow(state_manager).to receive(:schedule)
      allow(dispatcher).to receive(:register_handler) do |target, event_name, &handler|
        case event_name
        when 'failed'
          failed_proc = handler
        end
      end

      child_workflow_future = workflow_context.execute_workflow(MyTestWorkflow)

      # expect all futures to be false as nothing has happened
      expect(child_workflow_future.finished?).to be false
      expect(child_workflow_future.child_workflow_execution_future.finished?).to be false

      # dispatch the failed event and check what happens
      failed_proc.call(Temporal::Workflow::Errors.generate_error_for_child_workflow_start("failed to start", "random-workflow-id"))
      expect(child_workflow_future.failed?).to be true
      expect(child_workflow_future.child_workflow_execution_future.failed?).to be true
    end
  end

  describe '#execute_workflow!' do
    let(:child_workflow_future) do
      double = instance_double('Temporal::Workflow::ChildWorkflowFuture')
      allow(double).to receive(:get).and_return(result)
      double
    end

    before do
      expect(workflow_context).to receive(:execute_workflow).and_return(child_workflow_future)
    end

    context 'when future fails' do
      let(:result) { Temporal::WorkflowRunError }

      it 'raises the future result exception' do
        expect(child_workflow_future).to receive(:failed?).and_return(true)
        expect { workflow_context.execute_workflow!(MyTestWorkflow) }.to raise_error(result)
      end
    end

    context 'when future succeeds' do
      let(:result) { 'result' }

      it 'returns the future result' do
        expect(child_workflow_future).to receive(:failed?).and_return(false)
        expect(workflow_context.execute_workflow!(MyTestWorkflow)).to eq(result)
      end
    end
  end

  describe '#schedule_workflow' do
    let(:cron_schedule) { '* * * * *' }

    context 'when given workflow options' do
      it 'executes workflow with merged cron_schedule option' do
        expect(workflow_context).to receive(:execute_workflow).with(MyTestWorkflow,
          options: {
            parent_close_policy: :abandon,
            cron_schedule: cron_schedule
          }
        )
        workflow_context.schedule_workflow(MyTestWorkflow, cron_schedule, options: { parent_close_policy: :abandon })
      end
    end

    context 'when not given workflow options' do
      it 'executes workflow with cron_schedule option' do
        expect(workflow_context).to receive(:execute_workflow).with(MyTestWorkflow,
          options: {
            cron_schedule: cron_schedule
          }
        )
        workflow_context.schedule_workflow(MyTestWorkflow, cron_schedule)
      end
    end
  end

  describe '#upsert_search_attributes' do
    it 'does not accept nil' do
      expect do
        workflow_context.upsert_search_attributes(nil)
      end.to raise_error(ArgumentError, 'search_attributes cannot be nil')
    end

    it 'requires a hash' do
      expect do
        workflow_context.upsert_search_attributes(['array_not_supported'])
      end.to raise_error(ArgumentError, 'for search_attributes, expecting a Hash, not Array')
    end

    it 'requires a non-empty hash' do
      expect do
        workflow_context.upsert_search_attributes({})
      end.to raise_error(ArgumentError, 'Cannot upsert an empty hash for search_attributes, as this would do nothing.')
    end

    it 'creates a command to execute the request' do
      expect(state_manager).to receive(:schedule)
        .with an_instance_of(Temporal::Workflow::Command::UpsertSearchAttributes)
      workflow_context.upsert_search_attributes({ 'CustomIntField' => 5 })
    end

    it 'converts a Time to the ISO8601 UTC format expected by the Temporal server' do
      time = Time.now
      allow(state_manager).to receive(:schedule)
        .with an_instance_of(Temporal::Workflow::Command::UpsertSearchAttributes)

      expect(
        workflow_context.upsert_search_attributes({'CustomDatetimeField' => time})
      ).to eq({ 'CustomDatetimeField' => time.utc.iso8601 })
    end

    it 'gets latest search attributes from state_manager' do
      search_attributes = { 'CustomIntField' => 42 }
      expect(state_manager).to receive(:search_attributes).and_return(search_attributes)
      expect(workflow_context.search_attributes).to eq(search_attributes)
    end
  end

  describe '#name' do
    it 'returns the name from the metadata' do
      # Set in the :workflow_metadata Fabricator
      expect(workflow_context.name).to eq("TestWorkflow")
    end
  end

  describe '#wait_for_all' do
    let(:target_1) { 'target1' }
    let(:future_1) { Temporal::Workflow::Future.new(target_1, workflow_context) }
    let(:target_2) { 'target2' }
    let(:future_2) { Temporal::Workflow::Future.new(target_2, workflow_context) }

    def wait_for_all
      unblocked = false

      Fiber.new do
        workflow_context.wait_for_all(future_1, future_2)
        unblocked = true
      end.resume

      proc { unblocked }
    end

    it 'no futures returns immediately' do
      workflow_context.wait_for_all
    end

    it 'futures already finished' do
      future_1.set('done')
      future_2.set('also done')
      check_unblocked = wait_for_all

      expect(check_unblocked.call).to be(true)
    end

    it 'futures finished' do
      check_unblocked = wait_for_all

      future_1.set('done')
      dispatcher.dispatch(target_1, 'foo')
      expect(check_unblocked.call).to be(false)

      future_2.set('also done')
      dispatcher.dispatch(target_2, 'foo')
      expect(check_unblocked.call).to be(true)
    end
  end

  describe '#wait_for_any' do
    let(:target_1) { 'target1' }
    let(:future_1) { Temporal::Workflow::Future.new(target_1, workflow_context) }
    let(:target_2) { 'target2' }
    let(:future_2) { Temporal::Workflow::Future.new(target_2, workflow_context) }

    def wait_for_any
      unblocked = false

      Fiber.new do
        workflow_context.wait_for_any(future_1, future_2)
        unblocked = true
      end.resume

      proc { unblocked }
    end

    it 'no futures returns immediately' do
      workflow_context.wait_for_any
    end

    it 'one future already finished' do
      future_1.set("it's done")
      check_unblocked = wait_for_any

      expect(check_unblocked.call).to be(true)
    end

    it 'one future becomes finished' do
      check_unblocked = wait_for_any
      future_1.set("it's done")
      dispatcher.dispatch(target_1, 'foo')

      expect(check_unblocked.call).to be(true)

      # Dispatch a second time. This should not attempt to
      # resume the fiber which by now should already be dead.
      dispatcher.dispatch(target_1, 'foo')
    end

    it 'both futures becomes finished' do
      check_unblocked = wait_for_any
      future_1.set("it's done")
      future_2.set("it's done")
      dispatcher.dispatch(target_1, 'foo')
      dispatcher.dispatch(target_2, 'foo')

      expect(check_unblocked.call).to be(true)
    end

    it 'one future dispatched but not finished' do
      check_unblocked = wait_for_any
      dispatcher.dispatch(target_1, 'foo')

      expect(check_unblocked.call).to be(false)
    end

    context 'stack trace' do
      let(:track_stack_trace) { true }
      let(:query_registry) { Temporal::Workflow::QueryRegistry.new }

      it 'is recorded' do
        wait_for_any
        stack_trace = query_registry.handle(Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME)

        expect(stack_trace).to start_with('Fiber count: 1')
        expect(stack_trace).to include('block in wait_for_any')
      end

      it 'cleared after unblocked' do
        wait_for_any

        future_1.set("it's done")
        future_2.set("it's done")
        dispatcher.dispatch(target_1, 'foo')
        dispatcher.dispatch(target_2, 'foo')

        stack_trace = query_registry.handle(Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME)

        expect(stack_trace).to eq("Fiber count: 0\n")
      end
    end
  end

  describe '#wait_until' do
    def wait_until(&blk)
      unblocked = false

      Fiber.new do
        workflow_context.wait_until(&blk)
        unblocked = true
      end.resume

      proc { unblocked }
    end

    it 'block already true' do
      check_unblocked = wait_until { true }

      expect(check_unblocked.call).to be(true)
    end

    it 'block is always false' do
      check_unblocked = wait_until { false }

      dispatcher.dispatch('target', 'foo')
      expect(check_unblocked.call).to be(false)
    end

    it 'block becomes true' do
      value = false
      check_unblocked = wait_until { value }

      expect(check_unblocked.call).to be(false)

      dispatcher.dispatch('target', 'foo')
      expect(check_unblocked.call).to be(false)

      value = true
      dispatcher.dispatch('target', 'foo')
      expect(check_unblocked.call).to be(true)

      # Can dispatch again safely without resuming dead fiber
      dispatcher.dispatch('target', 'foo')
    end

    context 'stack trace' do
      let(:track_stack_trace) { true }
      let(:query_registry) { Temporal::Workflow::QueryRegistry.new }

      it 'is recorded' do
        wait_until { false }
        stack_trace = query_registry.handle(Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME)

        expect(stack_trace).to start_with('Fiber count: 1')
        expect(stack_trace).to include('block in wait_until')
      end

      it 'cleared after unblocked' do
        value = false
        wait_until { value }

        value = true
        dispatcher.dispatch('target', 'foo')

        stack_trace = query_registry.handle(Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME)

        expect(stack_trace).to eq("Fiber count: 0\n")
      end
    end
  end
end
