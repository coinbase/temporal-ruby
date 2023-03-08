require 'workflows/delegator_workflow'

describe 'Dynamic workflows' do
  let(:workflow_id) { SecureRandom.uuid }

  it 'can delegate to other classes' do
    # PlusExecutor and TimesExecutor do not subclass Workflow
    run_id = Temporal.start_workflow(
      PlusExecutor,
      {a: 5, b: 3},
      options: {
        workflow_id: workflow_id
      })

    result = Temporal.await_workflow_result(
      PlusExecutor,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(result[:computation]).to eq(8)

    run_id = Temporal.start_workflow(
      TimesExecutor,
      {a: 5, b: 3},
      options: {
        workflow_id: workflow_id
      })

    result = Temporal.await_workflow_result(
      TimesExecutor,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(result[:computation]).to eq(15)

  end
end
