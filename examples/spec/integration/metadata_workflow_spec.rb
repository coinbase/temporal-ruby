require 'workflows/metadata_workflow'

describe MetadataWorkflow, :integration do
  subject { described_class }

  it 'gets task queue from running workflow' do
    workflow_id = 'task-queue-' + SecureRandom.uuid
    run_id = Temporal.start_workflow(
      subject,
      options: { workflow_id: workflow_id }
    )

    actual_result = Temporal.await_workflow_result(
      subject,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    expect(actual_result.task_queue).to eq(integration_spec_task_queue)
  end

  it 'workflow can retrieve its headers' do
    workflow_id = 'header_test_wf-' + SecureRandom.uuid

    run_id = Temporal.start_workflow(
      MetadataWorkflow,
      options: {
          workflow_id: workflow_id,
          headers: { 'foo' => 'bar' },
      }
    )

    actual_result = Temporal.await_workflow_result(
      MetadataWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result.headers).to eq({ 'foo' => 'bar' })
  end

  it 'workflow can retrieve its run started at' do
    workflow_id = 'started_at_test_wf-' + SecureRandom.uuid

    run_id = Temporal.start_workflow(
      MetadataWorkflow,
      options: { workflow_id: workflow_id }
    )

    actual_result = Temporal.await_workflow_result(
      MetadataWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(Time.now - actual_result.run_started_at).to be_between(0, 30)
  end

  it 'gets memo from workflow execution info' do
    workflow_id = 'memo_execution_test_wf-' + SecureRandom.uuid
    run_id = Temporal.start_workflow(subject, options: { workflow_id: workflow_id, memo: { 'foo' => 'bar' } })

    actual_result = Temporal.await_workflow_result(
      subject,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result.memo['foo']).to eq('bar')

    expect(Temporal.fetch_workflow_execution_info(
      integration_spec_namespace, workflow_id, nil
    ).memo).to eq({ 'foo' => 'bar' })
  end

  it 'gets memo from workflow context with no memo' do
    workflow_id = 'memo_context_no_memo_test_wf-' + SecureRandom.uuid

    run_id = Temporal.start_workflow(
      subject,
      options: { workflow_id: workflow_id }
    )

    actual_result = Temporal.await_workflow_result(
      subject,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(actual_result.memo).to eq({})
    expect(Temporal.fetch_workflow_execution_info(
      integration_spec_namespace, workflow_id, nil
    ).memo).to eq({})
  end
end
