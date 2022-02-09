require 'workflows/workflow_signals_externally'

describe WaitForExternalSignalWorkflow do
  let(:signal_name) { "signal_name" }

  it 'receives signal from an external workflow' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      WaitForExternalSignalWorkflow,
      signal_name,
      options: { workflow_id: workflow_id }
    )

    Temporal.start_workflow(SendSignalToExternalWorkflow, signal_name, workflow_id)

    result = Temporal.await_workflow_result(
      WaitForExternalSignalWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to eq(
      {
        received: {
          signal_name => ["arg1", "arg2"]
        },
        counts: {
          signal_name => 1
        }
      }
    )
  end

  it 'correctly handles failure to deliver' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      SendSignalToExternalWorkflow,
      signal_name,
      workflow_id,
      options: { workflow_id: workflow_id })

    result = Temporal.await_workflow_result(
      SendSignalToExternalWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to eq(:failed)
  end
end
