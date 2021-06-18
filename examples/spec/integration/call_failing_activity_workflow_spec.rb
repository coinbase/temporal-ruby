require 'workflows/call_failing_activity_workflow'

describe CallFailingActivityWorkflow, :integration do

  class TestDeserializer
    include Temporal::Concerns::Payloads
  end

  it 'correctly re-raises an activity-thrown exception in the workflow' do
    workflow_id = SecureRandom.uuid
    expected_message = "a failure message"
    Temporal.start_workflow(described_class, expected_message, { options: { workflow_id: workflow_id } })
    history_response = wait_for_workflow_completion(workflow_id, nil)
    history = Temporal::Workflow::History.new(history_response.history.events)
    closed_event = history.events.first
    expect(closed_event.type).to eq('WORKFLOW_EXECUTION_COMPLETED')
    result = TestDeserializer.new.from_result_payloads(closed_event.attributes.result)
    expect(result[:class]).to eq(FailingActivity::MyError)
    expect(result[:message]).to eq(expected_message)
  end
end
