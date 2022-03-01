require 'workflows/upsert_search_attributes_workflow'

describe 'Temporal::Workflow::Context.upsert_search_attributes', :integration do
  it 'can upsert a search attribute and then retrieve it' do
    workflow_id = 'upsert_search_attributes_test_wf-' + SecureRandom.uuid

    expected_attributes = {
      'CustomStringField' => 'moo',
      'CustomBoolField' => true,
      'CustomDoubleField' => 3.14,
      'CustomIntField' => 0,
      'CustomDatetimeField' => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    run_id = Temporal.start_workflow(
      UpsertSearchAttributesWorkflow,
      *expected_attributes.values,
      options: {
        workflow_id: workflow_id,
      },
    )

    added_attributes = Temporal.await_workflow_result(
      UpsertSearchAttributesWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(added_attributes).to eq(expected_attributes)

    execution_info = Temporal.fetch_workflow_execution_info(
      integration_spec_namespace,
      workflow_id,
      nil
    )
    expect(execution_info.search_attributes).to eq(expected_attributes)
  end
end
