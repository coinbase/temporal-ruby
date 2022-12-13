require 'workflows/calls_delegator_workflow'

describe 'Dynamic activities' do
  let(:workflow_id) { SecureRandom.uuid }

  it 'can delegate to other classes' do
    run_id = Temporal.start_workflow(CallsDelegatorWorkflow, options: {
                                       workflow_id: workflow_id
                                     })

    result = Temporal.await_workflow_result(
      CallsDelegatorWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )
    expect(result[:sum]).to eq(8)
    expect(result[:product]).to eq(15)
  end
end
