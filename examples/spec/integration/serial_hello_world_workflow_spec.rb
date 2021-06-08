require 'workflows/serial_hello_world_workflow'

describe SerialHelloWorldWorkflow, :integration do
  it 'completes' do
    workflow_id, run_id = run_workflow(described_class, 'Alice', 'Bob', 'John')

    result = Temporal.await_workflow_result(
      described_class,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(result).to eq(nil)
  end
end
