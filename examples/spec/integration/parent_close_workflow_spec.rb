require 'workflows/parent_close_workflow'

describe ParentCloseWorkflow, :integration do
  subject { described_class }

  before { allow(SlowChildWorkflow).to receive(:stub).and_call_original }

  it 'SlowChildWorkflow terminates if parent_close_policy is TERMINATE' do
    workflow_id = 'parent_close_test_wf-' + SecureRandom.uuid
    child_workflow_id = 'slow_child_test_wf-' + SecureRandom.uuid

    run_id = Temporal.start_workflow(
      ParentCloseWorkflow,
      child_workflow_id,
      :terminate,
      options: { workflow_id: workflow_id }
    )

    Temporal.await_workflow_result(
      ParentCloseWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect do
      Temporal.await_workflow_result(
        SlowChildWorkflow,
        workflow_id: child_workflow_id,
      )
    end.to raise_error(Temporal::WorkflowTerminated)
  end

  it 'SlowChildWorkflow completes if parent_close_policy is ABANDON' do
    workflow_id = 'parent_close_test_wf-' + SecureRandom.uuid
    child_workflow_id = 'slow_child_test_wf-' + SecureRandom.uuid

    run_id = Temporal.start_workflow(
      ParentCloseWorkflow,
      child_workflow_id,
      :abandon,
      options: { workflow_id: workflow_id }
    )

    Temporal.await_workflow_result(
      ParentCloseWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    result = Temporal.await_workflow_result(
      SlowChildWorkflow,
      workflow_id: child_workflow_id,
    )

    expect(result).to eq('slow child ran')
  end
end
