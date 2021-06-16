require 'workflows/failing_workflow'
require 'workflows/result_workflow'
require 'workflows/quick_timeout_workflow'

describe 'Temporal.await_workflow_result' do
  [
    {type: 'hash', expected_result: { 'key' => 'value' }},
    {type: 'integer', expected_result: 5},
    {type: 'nil', expected_result: nil},
    {type: 'string', expected_result: 'a result'},
  ].each do |type:, expected_result:|
    it "completes and returns a #{type}" do
      workflow_id = SecureRandom.uuid
      run_id = Temporal.start_workflow(
        ResultWorkflow,
        expected_result,
        { options: { workflow_id: workflow_id } },
      )
      actual_result = Temporal.await_workflow_result(
        ResultWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
      expect(actual_result).to eq(expected_result)
    end
  end

  it 'allows the run ID to be left out and reports on the latest one' do
    workflow_id = SecureRandom.uuid
    expected_first_result = 17
    first_run_id = Temporal.start_workflow(
      ResultWorkflow,
      expected_first_result,
      { options: { workflow_id: workflow_id } },
    )
    actual_first_result = Temporal.await_workflow_result(
      ResultWorkflow,
      workflow_id: workflow_id,
    )
    expect(actual_first_result).to eq(expected_first_result)

    expected_second_result = 18
    Temporal.start_workflow(
      ResultWorkflow,
      expected_second_result,
      { options: { workflow_id: workflow_id } },
    )
    actual_second_result = Temporal.await_workflow_result(
      ResultWorkflow,
      workflow_id: workflow_id,
    )
    expect(actual_second_result).to eq(expected_second_result)

    # old run ID still works
    actual_old_result = Temporal.await_workflow_result(
      ResultWorkflow,
      workflow_id: workflow_id,
      run_id: first_run_id,
    )
    expect(actual_old_result).to eq(expected_first_result)
  end

  it 'is idempotent' do
    workflow_id = SecureRandom.uuid
    expected_result = 5
    run_id = Temporal.start_workflow(
      ResultWorkflow,
      expected_result,
      { options: { workflow_id: workflow_id } },
    )
    actual_result = Temporal.await_workflow_result(
      ResultWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result).to eq(expected_result)

    # We should be able to await after it's already complete (and indeed,
    # after we've already gotten the result.)
    actual_result = Temporal.await_workflow_result(
      ResultWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result).to eq(expected_result)

  end

  it 'raises for workflows that fail' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      FailingWorkflow,
      { options: { workflow_id: workflow_id } },
    )

    expect do
      Temporal.await_workflow_result(
        FailingWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowFailed) do |e|
      expect(e.stack_trace).to match(/failing_workflow.rb/)
      expect(e.message).to eq('Whoops')
    end
  end

  it 'raises Temporal::WorkflowTimedOut when the workflow times out' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      QuickTimeoutWorkflow,
      { options: { workflow_id: workflow_id } },
    )

    expect do
      Temporal.await_workflow_result(
        QuickTimeoutWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowTimedOut)
  end

  it 'raises Temporal::WorkflowContinuedAsNew when the workflow continues as new' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      LoopWorkflow,
      2, # it continues as new if this arg is > 1
      { options: { workflow_id: workflow_id } },
    )

    expect do
      Temporal.await_workflow_result(
        LoopWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowContinuedAsNew) do |error|
      expect(error.new_run_id).to_not eq(nil)
    end
  end
end
