require 'workflows/memo_workflow'

describe MemoWorkflow do
  subject { described_class }

  it 'gets memo from workflow execution info' do
    workflow_id = 'memo_execution_test_wf'

    begin
      Temporal.terminate_workflow(workflow_id)
    rescue GRPC::NotFound => _
      # The test workflow hasn't been scheduled before
    end
    
    run_id = Temporal.start_workflow(MemoWorkflow, options: {workflow_id: workflow_id, memo: { 'foo' => 'bar' } })

    actual_result = Temporal.await_workflow_result(
      MemoWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result).to eq('bar')

    expect(Temporal.fetch_workflow_execution_info(
      'ruby-samples', workflow_id, nil
    ).memo).to eq({ 'foo' => 'bar' })
  end

  it 'gets memo from workflow context with no memo' do
    workflow_id = 'memo_context_no_memo_test_wf'

    begin
      Temporal.terminate_workflow(workflow_id)
    rescue GRPC::NotFound => _
      # The test workflow hasn't been scheduled before
    end

    run_id = Temporal.start_workflow(
      MemoWorkflow,
      options: { workflow_id: workflow_id }
    )

    actual_result = Temporal.await_workflow_result(
      MemoWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result).to eq(nil)
  end
end
