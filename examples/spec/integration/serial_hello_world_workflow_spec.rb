require 'workflows/serial_hello_world_workflow'

describe SerialHelloWorldWorkflow, :integration do
  it 'completes' do
    workflow_id, run_id = run_workflow(described_class, 'Alice', 'Bob', 'John')

    result = fetch_history(
      workflow_id,
      run_id,
      wait_for_new_event: true,
      event_type: :close,
    )

    expect(result.history.events.first.event_type).to eq(:EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED)
  end
end
