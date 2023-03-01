require 'workflows/hello_world_workflow'
require 'workflows/long_workflow'

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

  it 'rejects duplicate workflow ids based on workflow_id_reuse_policy' do
    # Run it once...
    run_id = Temporal.start_workflow(HelloWorldWorkflow, 'Test', options: {
      workflow_id: workflow_id,
    })

    result = Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    expect(result).to eq('Hello World, Test')

    # And again, allowing duplicates...
    run_id = Temporal.start_workflow(HelloWorldWorkflow, 'Test', options: {
      workflow_id: workflow_id,
      workflow_id_reuse_policy: :allow
    })

    Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    # And again, rejecting duplicates...
    expect do
      Temporal.start_workflow(HelloWorldWorkflow, 'Test', options: {
        workflow_id: workflow_id,
        workflow_id_reuse_policy: :reject
      })
    end.to raise_error(Temporal::WorkflowExecutionAlreadyStartedFailure)
  end

  it 'terminates duplicate workflow ids based on workflow_id_reuse_policy' do
    run_id_1 = Temporal.start_workflow(LongWorkflow, options: {
      workflow_id: workflow_id,
      workflow_id_reuse_policy: :terminate_if_running
    })

    run_id_2 = Temporal.start_workflow(LongWorkflow, options: {
      workflow_id: workflow_id,
      workflow_id_reuse_policy: :terminate_if_running
    })

    execution_1 = Temporal.fetch_workflow_execution_info(
      Temporal.configuration.namespace,
      workflow_id,
      run_id_1)
    execution_2 = Temporal.fetch_workflow_execution_info(
      Temporal.configuration.namespace,
      workflow_id,
      run_id_2)

    expect(execution_1.status).to eq(Temporal::Workflow::Status::TERMINATED)
    expect(execution_2.status).to eq(Temporal::Workflow::Status::RUNNING)
  end
end
