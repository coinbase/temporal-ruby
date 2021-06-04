require 'workflows/timeout_workflow'

describe 'Temporal.terminate_workflow' do
  it 'can terminate a running workflow' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      TimeoutWorkflow,
      1, # sleep long enough to be sure I can cancel in time.
      1,
      { options: { workflow_id: workflow_id } },
    )

    Temporal.terminate_workflow(workflow_id)

    expect do
      Temporal.await_workflow_result(
        workflow: TimeoutWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowTerminated)
  end
end
