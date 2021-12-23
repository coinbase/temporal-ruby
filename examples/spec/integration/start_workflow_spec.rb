require 'workflows/hello_world_workflow'

describe 'Temporal.start_workflow' do
  let(:workflow_id) { SecureRandom.uuid }

  it 'starts a workflow using a class reference' do
    run_id = Temporal.start_workflow(HelloWorldWorkflow, 'Test', options: {
      workflow_id: workflow_id
    })

    result = Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    expect(result).to eq('Hello World, Test')
  end

  it 'starts a workflow using a string reference' do
    run_id = Temporal.start_workflow('HelloWorldWorkflow', 'Test', options: {
      workflow_id: workflow_id,
      namespace: Temporal.configuration.namespace,
      task_queue: Temporal.configuration.task_queue
    })

    result = Temporal.await_workflow_result(
      'HelloWorldWorkflow',
      workflow_id: workflow_id,
      run_id: run_id,
      namespace: Temporal.configuration.namespace
    )

    expect(result).to eq('Hello World, Test')
  end
end
