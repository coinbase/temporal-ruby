require 'workflows/handling_structured_error_workflow'

describe HandlingStructuredErrorWorkflow, :integration do
  it 'correctly re-raises an activity-thrown exception in the workflow' do
    workflow_id = SecureRandom.uuid

    Temporal.start_workflow(described_class, 'foo', 5.0, options: { workflow_id: workflow_id })

    result = Temporal.await_workflow_result(described_class, workflow_id: workflow_id)
    expect(result).to eq('success')
  end

end
