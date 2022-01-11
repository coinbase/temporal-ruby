require 'temporal/testing'
require 'temporal/workflow'
require 'temporal/api/errordetails/v1/message_pb'

describe Temporal::Testing::LocalWorkflowContext do
  let(:workflow_id) { 'workflow_id_1' }
  let(:run_id) { 'run_id_1' }
  let(:execution) { Temporal::Testing::WorkflowExecution.new }
  let(:task_queue) { 'my_test_queue' }
  let(:workflow_context) do
    Temporal::Testing::LocalWorkflowContext.new(
      execution,
      workflow_id,
      run_id,
      [],
      Temporal::Metadata::Workflow.new(
        namespace: 'ruby-samples',
        id: workflow_id,
        name: 'HelloWorldWorkflow',
        run_id: run_id,
        attempt: 1,
        task_queue: task_queue,
        headers: {},
        run_started_at: Time.now,
        memo: {},
      )
    )
  end
  let(:async_token) do
    # Generate the async token
    Temporal::Activity::AsyncToken.encode(
      Temporal.configuration.namespace,
      1, # activity ID starts at 1 for each workflow
      workflow_id,
      run_id
    )
  end

  class TestHeartbeatingActivity < Temporal::Activity
    def execute
      activity.heartbeat
    end
  end

  class TestFailedActivity < Temporal::Activity
    def execute
      raise 'oops'
    end
  end

  class TestActivity < Temporal::Activity
    def execute
      'ok'
    end
  end

  class TestAsyncActivity < Temporal::Activity
    def execute
      activity.async
    end
  end

  class MetadataCapturingActivity < Temporal::Activity
    def execute
      activity.metadata
    end
  end

  describe '#execute_activity' do
    describe 'outcome is captured in the future' do
      it 'delay failure' do
        allow(Temporal::ErrorHandler).to receive(:handle)
        f = workflow_context.execute_activity(TestFailedActivity)
        f.wait

        expect(f.failed?).to be true
        expect(f.finished?).to be true
        expect(f.ready?).to be false

        expect(f.get).to be_a(RuntimeError)
        expect(f.get.message).to eq('oops')

        expect(Temporal::ErrorHandler).to have_received(:handle)
          .with(f.get, kind_of(Temporal::Configuration), hash_including(metadata: kind_of(Temporal::Metadata::Activity)))
      end

      it 'successful synchronous result' do
        f = workflow_context.execute_activity(TestActivity)
        f.wait

        expect(f.failed?).to be false
        expect(f.finished?).to be true
        expect(f.ready?).to be true

        expect(f.get).to eq('ok')
      end

      it 'successful asynchronous result' do
        f = workflow_context.execute_activity(TestAsyncActivity)

        expect(f.failed?).to be false
        expect(f.finished?).to be false
        expect(f.ready?).to be false

        execution.complete_activity(async_token, 'async_ok')

        expect(f.failed?).to be false
        expect(f.finished?).to be true
        expect(f.ready?).to be true

        expect(f.get).to eq('async_ok')
      end

      it 'failed asynchronous result' do
        f = workflow_context.execute_activity(TestAsyncActivity)

        expect(f.failed?).to be false
        expect(f.finished?).to be false
        expect(f.ready?).to be false

        error = StandardError.new('crash')
        execution.fail_activity(async_token, error)

        expect(f.failed?).to be true
        expect(f.finished?).to be true
        expect(f.ready?).to be false

        expect(f.get).to eq(error)
      end
    end
  end

  describe '#execute_activity!' do
    it 'immediate failure raises' do
      expect {
          workflow_context.execute_activity!(TestFailedActivity)
      }.to raise_error(RuntimeError, 'oops')
    end

    it 'success returns' do
      result = workflow_context.execute_activity!(TestActivity)
      expect(result).to eq('ok')
    end

    it 'can heartbeat' do
      # Heartbeat doesn't do anything in local mode, but at least it can be called.
      workflow_context.execute_activity!(TestHeartbeatingActivity)
    end

    it 'has accurate metadata' do
      result = workflow_context.execute_activity!(MetadataCapturingActivity)
      expect(result.attempt).to eq(1)
      expect(result.headers).to eq({})
      expect(result.id).to eq(1)
      expect(result.name).to eq('MetadataCapturingActivity')
      expect(result.namespace).to eq('default-namespace')
      expect(result.workflow_id).to eq(workflow_id)
      expect(result.workflow_run_id).to eq(run_id)
    end
  end

  describe '#wait_for' do
    it 'await unblocks once condition changes' do
      can_continue = false
      exited = false
      fiber = Fiber.new do
        workflow_context.wait_for do
          can_continue
        end

        exited = true
      end

      fiber.resume # start running
      expect(exited).to eq(false)

      can_continue = true # change condition
      fiber.resume # resume running after the Fiber.yield done in context.await
      expect(exited).to eq(true)
    end

    it 'condition or future unblocks' do
      exited = false

      future = workflow_context.execute_activity(TestAsyncActivity)

      fiber = Fiber.new do
        workflow_context.wait_for(future) do
          false
        end

        exited = true
      end

      fiber.resume # start running
      expect(exited).to eq(false)

      execution.complete_activity(async_token, 'async_ok')

      fiber.resume # resume running after the Fiber.yield done in context.await
      expect(exited).to eq(true)
    end

    it 'any future unblocks' do
      exited = false

      async_future = workflow_context.execute_activity(TestAsyncActivity)
      future = workflow_context.execute_activity(TestActivity)
      future.wait

      fiber = Fiber.new do
        workflow_context.wait_for(future, async_future)
        exited = true
      end

      fiber.resume # start running
      expect(exited).to eq(true)
    end
  end
end
