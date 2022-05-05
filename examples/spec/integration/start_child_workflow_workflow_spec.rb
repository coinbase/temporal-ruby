require 'workflows/start_child_workflow_workflow'

describe StartChildWorkflowWorkflow, :integration do
  subject { described_class }

  it 'StartChildWorkflowWorkflow returns the child workflows information on the start future' do
    workflow_id = 'parent_close_test_wf-' + SecureRandom.uuid
    child_workflow_id = 'slow_child_test_wf-' + SecureRandom.uuid

    run_id = Temporal.start_workflow(
      StartChildWorkflowWorkflow,
      child_workflow_id,
      options: { workflow_id: workflow_id }
    )

    result = Temporal.await_workflow_result(
      StartChildWorkflowWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result.workflow_id).to start_with(child_workflow_id)
  end
end
