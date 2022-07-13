require 'workflows/upsert_search_attributes_workflow'
require 'time'

describe 'Temporal::Client.start_workflow', :integration do
  it 'can start a workflow with initial search attributes' do
    workflow_id = 'initial_search_attributes_test_wf-' + SecureRandom.uuid
    expected_binary_checksum = `git show HEAD -s --format=%H`.strip

    initial_search_attributes = {
      'CustomBoolField' => false,
      'CustomIntField' => -1,
      'CustomDatetimeField' => Time.now.utc.iso8601,
      # These should get overriden when the workflow upserts them
      'CustomStringField' => 'meow',
      'CustomDoubleField' => 6.28,
    }
    upserted_search_attributes = {
      'CustomStringField' => 'moo',
      'CustomDoubleField' => 3.14,
    }
    expected_custom_attributes = initial_search_attributes.merge(upserted_search_attributes)

    run_id = Temporal.start_workflow(
      UpsertSearchAttributesWorkflow,
      string_value: upserted_search_attributes['CustomStringField'],
      float_value: upserted_search_attributes['CustomDoubleField'],
      options: {
        workflow_id: workflow_id,
        search_attributes: initial_search_attributes,
      },
    )

    added_attributes = Temporal.await_workflow_result(
      UpsertSearchAttributesWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(added_attributes).to eq(upserted_search_attributes)

    # These attributes are set for the worker in bin/worker
    expected_attributes = {
      # Contains a list of all binary checksums seen for this workflow execution
      'BinaryChecksums' => [expected_binary_checksum]
    }.merge(expected_custom_attributes)

    execution_info = Temporal.fetch_workflow_execution_info(
      integration_spec_namespace,
      workflow_id,
      nil
    )
    expect(execution_info.search_attributes).to eq(expected_attributes)
  end
end
