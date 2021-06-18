require 'workflows/call_failing_activity_workflow'

describe CallFailingActivityWorkflow do
  it 'correctly re-raises an activity-thrown exception in the workflow' do
    workflow_id = SecureRandom.uuid
    expected_message = "a failure message"
    Temporal.start_workflow(described_class, expected_message, { options: { workflow_id: workflow_id } })
    result = Temporal.await_workflow_result(
      described_class,
      workflow_id: workflow_id,
    )
    expect(result[:class]).to eq(FailingActivity::MyError)
    expect(result[:message]).to eq(expected_message)
  end
end
