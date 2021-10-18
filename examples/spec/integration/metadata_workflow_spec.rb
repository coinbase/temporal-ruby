require 'workflows/metadata_workflow'

describe MetadataWorkflow do
  subject { described_class }

  it 'gets task queue from running workflow' do
    workflow_id = 'task-queue-' + SecureRandom.uuid
    run_id = Temporal.start_workflow(
      subject,
      { options: { workflow_id: workflow_id } },
    )
    actual_result = Temporal.await_workflow_result(
      subject,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result.task_queue).to eq(Temporal.configuration.task_queue)
  end
end
