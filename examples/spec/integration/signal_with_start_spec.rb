require 'workflows/signal_with_start_workflow'

describe 'signal with start' do

  it 'signals at workflow start time' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      SignalWithStartWorkflow,
      'signal_name',
      0.1,
      signal_name: 'signal_name',
      signal_input: 'expected value',
      options: { workflow_id: workflow_id }
    )

    result = Temporal.await_workflow_result(
      SignalWithStartWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to eq('expected value') # the workflow should return the signal value
  end

  it 'signals at workflow start time with name only' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      SignalWithStartWorkflow,
      'signal_name',
      0.1,
      signal_name: 'signal_name',
      options: { workflow_id: workflow_id }
    )

    result = Temporal.await_workflow_result(
      SignalWithStartWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to eq(nil) # the workflow should return the signal value
  end

  it 'does not launch a new workflow when signaling a running workflow through signal_with_start' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      SignalWithStartWorkflow,
      'signal_name',
      10,
      signal_name: 'signal_name',
      signal_input: 'expected value',
      options: { workflow_id: workflow_id }
    )

    second_run_id = Temporal.start_workflow(
      SignalWithStartWorkflow,
      'signal_name',
      0.1,
      signal_name: 'signal_name',
      signal_input: 'expected value',
      options: { workflow_id: workflow_id }
    )

    # If the run ids are the same, then we didn't start a new workflow
    expect(second_run_id).to eq(run_id)
  end
end
