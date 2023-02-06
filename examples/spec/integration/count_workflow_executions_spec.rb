require 'workflows/count_workflow'
require 'securerandom'

describe 'Temporal.count_workflow_executions', :integration do
  it 'counts 0 workflows when none match' do
    result = Temporal.connection.count_workflow_executions(
      namespace: Temporal.configuration.namespace, query: 'WorkflowType="ThisDoesntExistWorkflow"'
    )

    expect(result.count).to eq(0)
  end

  it 'counts workflows correctly' do
    workflow_id, run_id = run_workflow(CountWorkflow)

    Temporal.await_workflow_result(
      CountWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    # need to loop to check result here as count_workflow_executions is eventually
    # consistent
    found_correct_result = false
    count = 0
    while count < 15 && !found_correct_result
      result = Temporal.connection.count_workflow_executions(
        namespace: Temporal.configuration.namespace, query: "WorkflowId=\"#{workflow_id}\""
      )

      sleep 2

      # should return result == 1
      found_correct_result = result.count == 1
      count += 1
    end

    expect(found_correct_result).to eq(true)
  end
end
