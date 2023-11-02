# frozen_string_literal: true

describe 'Temporal.count_workflow_executions', :integration do
  it 'returns the number of workflows matching the provided query' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      HelloWorldWorkflow,
      'Test',
      options: { workflow_id: workflow_id }
    )

    Temporal.await_workflow_result(
      HelloWorldWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    query = "WorkflowType = \"HelloWorldWorkflow\" AND WorkflowId = \"#{workflow_id}\""

    # This is a workaround for the fact that this API hits the visibility store and there's a lag
    # before the workflow gets indexed
    result = nil

    5.times do
      result = Temporal.count_workflow_executions(
        'ruby-samples', query: query
      )

      break if result.positive?

      sleep 1
    end

    expect(result).to eq(1)
  end
end
