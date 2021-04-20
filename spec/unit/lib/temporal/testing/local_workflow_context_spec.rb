require 'temporal/testing'
require 'temporal/workflow'
require 'temporal/api/errordetails/v1/message_pb'

describe Temporal::Testing::LocalWorkflowContext do
  let(:workflow_id) { 'workflow_id_1' }
  let(:run_id) { 'run_id_1' }
  let(:execution) { Temporal::Testing::WorkflowExecution.new }
  let(:workflow_context) do
    Temporal::Testing::LocalWorkflowContext.new(
      execution,
      workflow_id,
      run_id,
      [],
      Temporal::Metadata::Workflow.new(name: workflow_id, run_id: run_id, attempt: 1)
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

  describe '#execute_activity' do
    describe 'outcome is captured in the future' do
      it 'delay failure' do
        f = workflow_context.execute_activity(TestFailedActivity)
        f.wait

        expect(f.failed?).to be true
        expect(f.finished?).to be true
        expect(f.ready?).to be false

        expect(f.get).to be_a(RuntimeError)
        expect(f.get.message).to eq('oops')
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
  end

  it 'can heartbeat' do
    # Heartbeat doesn't do anything in local mode, but at least it can be called.
    workflow_context.execute_activity!(TestHeartbeatingActivity)
  end
end
