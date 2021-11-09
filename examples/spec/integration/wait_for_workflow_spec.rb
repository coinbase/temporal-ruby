require 'workflows/wait_for_workflow'

describe WaitForWorkflow do

  it 'signals at workflow start time' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      WaitForWorkflow,
      10, # number of echo activities to run
      2, # max activity parallelism
      'signal_name',
      options: { workflow_id: workflow_id }
    )

    Temporal.signal_workflow(WaitForWorkflow, 'signal_name', workflow_id, run_id)

    result = Temporal.await_workflow_result(
      WaitForWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(result.length).to eq(3)
    expect(result[:signal]).to eq(true)
    expect(result[:timer]).to eq(true)
    expect(result[:activity]).to eq(true)
  end
end