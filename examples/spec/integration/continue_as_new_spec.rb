require 'workflows/continue_as_new_workflow'
require 'workflows/loop_workflow'

describe LoopWorkflow do
  it 'workflow continues as new into a new run' do
    workflow_id = SecureRandom.uuid
    memo = {
        'my-memo' => 'foo',
    }
    headers = {
        'my-header' => 'bar',
        'test-header' => 'test',
    }
    run_id = Temporal.start_workflow(
      LoopWorkflow,
      2, # it continues as new if this arg is > 1
      options: {
        workflow_id: workflow_id,
        memo: memo,
        headers: headers,
      },
    )

    # First run will throw because it continued as new
    next_run_id = nil
    expect do
      Temporal.await_workflow_result(
        LoopWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowRunContinuedAsNew) do |error|
      next_run_id = error.new_run_id
    end

    expect(next_run_id).to_not eq(nil)

    # Second run will not throw because it returns rather than continues as new.
    final_result = Temporal.await_workflow_result(
      LoopWorkflow,
      workflow_id: workflow_id,
      run_id: next_run_id,
    )

    expect(final_result[:count]).to eq(1)

    # memo and headers should be copied to the next run automatically
    expect(final_result[:memo]).to eq(memo)
    expect(final_result[:headers]).to eq(headers)
  end

  it 'uses history bytes size to continue as new' do
    workflow_id = SecureRandom.uuid
    # 7 activity invocations produce about 10,000 bytes of history. This should
    # result in one continue as new with 7 activities in the first and 3 in the
    # second run.
    run_id = Temporal.start_workflow(
      ContinueAsNewWorkflow,
      10, # hello count
      10_000, # max bytes limit
      options: {
        workflow_id: workflow_id,
        timeouts: {
          execution: 60,
          run: 20
        }
      },
    )

    # First run will throw because it continued as new
    next_run_id = nil
    expect do
      Temporal.await_workflow_result(
        ContinueAsNewWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowRunContinuedAsNew) do |error|
      next_run_id = error.new_run_id
    end

    expect(next_run_id).to_not eq(nil)

    # Second run will not throw because it returns rather than continues as new.
    final_result = Temporal.await_workflow_result(
      ContinueAsNewWorkflow,
      workflow_id: workflow_id,
      run_id: next_run_id,
    )

    expect(final_result[:runs]).to eq(2)
  end
end
