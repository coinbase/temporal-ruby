require 'workflows/hello_world_workflow'
require 'workflows/query_workflow'
require 'temporal/reset_reapply_type'

describe 'Temporal.reset_workflow' do
  it 'can reset a closed workflow to the beginning' do
    workflow_id = SecureRandom.uuid
    original_run_id = Temporal.start_workflow(
      HelloWorldWorkflow,
      'Test',
      options: { workflow_id: workflow_id }
    )

    original_result = Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: original_run_id
    )
    expect(original_result).to eq('Hello World, Test')

    new_run_id = Temporal.reset_workflow(
      Temporal.configuration.namespace,
      workflow_id,
      original_run_id,
      strategy: Temporal::ResetStrategy::FIRST_WORKFLOW_TASK
    )

    new_result = Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: new_run_id,
    )
    expect(new_result).to eq('Hello World, Test')
  end

  def reset_hello_world_workflow_twice(workflow_id, original_run_id, request_id:)
    2.times.map do
      new_run_id = Temporal.reset_workflow(
        Temporal.configuration.namespace,
        workflow_id,
        original_run_id,
        strategy: Temporal::ResetStrategy::FIRST_WORKFLOW_TASK,
        request_id: request_id
      )

      new_result = Temporal.await_workflow_result(
        HelloWorldWorkflow,
        workflow_id: workflow_id,
        run_id: new_run_id,
      )
      expect(new_result).to eq('Hello World, Test')

      new_run_id
    end
  end

  it 'can repeatedly reset the same closed workflow to the beginning' do
    workflow_id = SecureRandom.uuid
    original_run_id = Temporal.start_workflow(
      HelloWorldWorkflow,
      'Test',
      options: { workflow_id: workflow_id }
    )

    original_result = Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: original_run_id,
    )
    expect(original_result).to eq('Hello World, Test')

    new_run_ids = reset_hello_world_workflow_twice(
      workflow_id,
      original_run_id,
      # This causes the request_id to be generated with a random value:
      request_id: nil
    )

    # Each Reset request should have resulted in a unique workflow execution
    expect(new_run_ids.uniq.size).to eq(new_run_ids.size)
  end

  it 'can deduplicate reset requests' do
    workflow_id = SecureRandom.uuid
    original_run_id = Temporal.start_workflow(
      HelloWorldWorkflow,
      'Test',
      options: { workflow_id: workflow_id }
    )

    original_result = Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: original_run_id,
    )
    expect(original_result).to eq('Hello World, Test')

    reset_request_id = SecureRandom.uuid
    new_run_ids = reset_hello_world_workflow_twice(
      workflow_id,
      original_run_id,
      request_id: reset_request_id
    )

    # Each Reset request except the first should have been deduplicated
    expect(new_run_ids.uniq.size).to eq(1)
  end

  def start_query_workflow_and_signal_three_times
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      QueryWorkflow,
      options: { workflow_id: workflow_id }
    )

    expect(Temporal.query_workflow(QueryWorkflow, 'signal_count', workflow_id, run_id))
      .to eq 0

    Temporal.signal_workflow(QueryWorkflow, 'make_progress', workflow_id, run_id)
    Temporal.signal_workflow(QueryWorkflow, 'make_progress', workflow_id, run_id)
    Temporal.signal_workflow(QueryWorkflow, 'make_progress', workflow_id, run_id)

    expect(Temporal.query_workflow(QueryWorkflow, 'signal_count', workflow_id, run_id))
      .to eq 3

    { workflow_id: workflow_id, run_id: run_id }
  end

  it 'can reapply signals when resetting a workflow' do
    workflow_id, original_run_id = start_query_workflow_and_signal_three_times.values_at(:workflow_id, :run_id)

    new_run_id = Temporal.reset_workflow(
      Temporal.configuration.namespace,
      workflow_id,
      original_run_id,
      strategy: Temporal::ResetStrategy::FIRST_WORKFLOW_TASK,
      reset_reapply_type: Temporal::ResetReapplyType::SIGNAL
    )

    expect(Temporal.query_workflow(QueryWorkflow, 'signal_count', workflow_id, new_run_id))
      .to eq 3

    Temporal.terminate_workflow(workflow_id, run_id: new_run_id)
  end

  it 'can skip reapplying signals when resetting a workflow' do
    workflow_id, original_run_id = start_query_workflow_and_signal_three_times.values_at(:workflow_id, :run_id)

    new_run_id = Temporal.reset_workflow(
      Temporal.configuration.namespace,
      workflow_id,
      original_run_id,
      strategy: Temporal::ResetStrategy::FIRST_WORKFLOW_TASK,
      reset_reapply_type: Temporal::ResetReapplyType::NONE
    )

    expect(Temporal.query_workflow(QueryWorkflow, 'signal_count', workflow_id, new_run_id))
      .to eq 0

    Temporal.terminate_workflow(workflow_id, run_id: new_run_id)
  end
end
  