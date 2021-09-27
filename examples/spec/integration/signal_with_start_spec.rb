require 'workflows/signal_with_start_workflow'

describe 'signal with start' do

  it 'signals at workflow start time' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.signal_or_start_workflow(
      SignalWithStartWorkflow,
      'signal_name', # the actual signal name
      'expected value',
      'signal_name', # the expected signal name, which the workflow takes as an arg
      0.1, # how long to sleep for
      options: { workflow_id: workflow_id }
    )

    result = Temporal.await_workflow_result(
      SignalWithStartWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result).to eq('expected value') # the workflow should return the signal value
  end

  it 'does not launch a new workflow when signaling a running workflow through signal_or_start' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.signal_or_start_workflow(
      SignalWithStartWorkflow,
      'signal_name', # the actual signal name
      'expected value',
      'signal_name', # the expected signal name, which the workflow takes as an arg
      10, # how long to sleep for
      options: { workflow_id: workflow_id }
    )

    second_run_id = Temporal.signal_or_start_workflow(
      SignalWithStartWorkflow,
      'signal_name', # the actual signal name
      'expected value',
      'signal_name', # the expected signal name, which the workflow takes as an arg
      0.1, # how long to sleep for
      options: { workflow_id: workflow_id }
    )

    # If the run ids are the same, then we didn't start a new workflow
    expect(second_run_id).to eq(run_id)
  end

end
