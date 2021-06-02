require 'workflows/failing_workflow'
require 'workflows/result_workflow'
require 'workflows/timeout_workflow'
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
        workflow: ResultWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
      expect(actual_result).to eq(expected_result)
    end
  end

  it 'raises for workflows that fail' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      FailingWorkflow,
      { options: { workflow_id: workflow_id } },
    )

    expect do
      Temporal.await_workflow_result(
        workflow: FailingWorkflow,
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
        workflow: QuickTimeoutWorkflow,
        workflow_id: workflow_id,
        run_id: run_id,
      )
    end.to raise_error(Temporal::WorkflowTimedOut)
  end

end
