require 'workflows/parent_id_reuse_workflow'

describe ParentIdReuseWorkflow, :integration do
  subject { described_class }

  it 'with :allow, allows duplicates' do
    workflow_id = 'parent_id_reuse_wf-' + SecureRandom.uuid
    child_workflow_id = 'child_id_reuse_wf-' + SecureRandom.uuid

    Temporal.start_workflow(
      ParentIdReuseWorkflow,
      child_workflow_id,
      child_workflow_id,
      false,
      :allow,
      options: { workflow_id: workflow_id }
    )

    Temporal.await_workflow_result(
      ParentIdReuseWorkflow,
      workflow_id: workflow_id,
    )
  end

  it 'with :reject, rejects duplicates' do
    workflow_id = 'parent_id_reuse_wf-' + SecureRandom.uuid
    child_workflow_id = 'child_id_reuse_wf-' + SecureRandom.uuid

    Temporal.start_workflow(
      ParentIdReuseWorkflow,
      child_workflow_id,
      child_workflow_id,
      false,
      :reject,
      options: { workflow_id: workflow_id }
    )

    expect do
      Temporal.await_workflow_result(
        ParentIdReuseWorkflow,
        workflow_id: workflow_id,
      )
    end.to raise_error(StandardError, "The child workflow could not be started. Reason: START_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_WORKFLOW_ALREADY_EXISTS")
  end

  it 'with :reject, does not reject non-duplicates' do
    workflow_id = 'parent_id_reuse_wf-' + SecureRandom.uuid
    child_workflow_id_1 = 'child_id_reuse_wf-' + SecureRandom.uuid
    child_workflow_id_2 = 'child_id_reuse_wf-' + SecureRandom.uuid

    Temporal.start_workflow(
      ParentIdReuseWorkflow,
      child_workflow_id_1,
      child_workflow_id_2,
      false,
      :reject,
      options: { workflow_id: workflow_id }
    )

    Temporal.await_workflow_result(
      ParentIdReuseWorkflow,
      workflow_id: workflow_id,
    )
  end

  it 'with :allow_failed, allows duplicates after failure' do
    workflow_id = 'parent_id_reuse_wf-' + SecureRandom.uuid
    child_workflow_id = 'child_id_reuse_wf-' + SecureRandom.uuid

    Temporal.start_workflow(
      ParentIdReuseWorkflow,
      child_workflow_id,
      child_workflow_id,
      true,
      :allow_failed,
      options: { workflow_id: workflow_id }
    )

    Temporal.await_workflow_result(
      ParentIdReuseWorkflow,
      workflow_id: workflow_id,
    )
  end

  it 'with :allow_failed, rejects duplicates after success' do
    workflow_id = 'parent_id_reuse_wf-' + SecureRandom.uuid
    child_workflow_id = 'child_id_reuse_wf-' + SecureRandom.uuid

    Temporal.start_workflow(
      ParentIdReuseWorkflow,
      child_workflow_id,
      child_workflow_id,
      false,
      :allow_failed,
      options: { workflow_id: workflow_id }
    )

    expect do
      Temporal.await_workflow_result(
        ParentIdReuseWorkflow,
        workflow_id: workflow_id,
      )
    end.to raise_error(StandardError, "The child workflow could not be started. Reason: START_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_WORKFLOW_ALREADY_EXISTS")
  end
end
