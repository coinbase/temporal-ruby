require 'workflows/call_failing_activity_workflow'

describe CallFailingActivityWorkflow, :integration do

  class TestDeserializer
    include Temporal::Concerns::Payloads
  end

  it 'correctly re-raises an activity-thrown exception in the workflow' do
    workflow_id = SecureRandom.uuid
    expected_message = "a failure message"
    Temporal.start_workflow(described_class, expected_message, options: { workflow_id: workflow_id })
    expect do
      Temporal.await_workflow_result(described_class, workflow_id: workflow_id)
    end.to raise_error(FailingActivity::MyError, "a failure message")
  end
end
