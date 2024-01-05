require 'workflows/upsert_search_attributes_workflow'
require 'time'

describe 'Temporal::Workflow::Context.upsert_search_attributes', :integration do
  it 'can upsert a search attribute and then retrieve it' do
    workflow_id = 'upsert_search_attributes_test_wf-' + SecureRandom.uuid
    expected_binary_checksum = `git show HEAD -s --format=%H`.strip

    expected_added_attributes = {
      'CustomStringField' => 'moo',
      'CustomBoolField' => true,
      'CustomDoubleField' => 3.14,
      'CustomIntField' => 0,
      'CustomDatetimeField' => Time.now.utc.iso8601,
    }

    run_id = Temporal.start_workflow(
      UpsertSearchAttributesWorkflow,
      string_value: expected_added_attributes['CustomStringField'],
      bool_value: expected_added_attributes['CustomBoolField'],
      float_value: expected_added_attributes['CustomDoubleField'],
      int_value: expected_added_attributes['CustomIntField'],
      time_value: expected_added_attributes['CustomDatetimeField'],
      options: {
        workflow_id: workflow_id,
      },
    )

    added_attributes = Temporal.await_workflow_result(
      UpsertSearchAttributesWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(added_attributes).to eq(expected_added_attributes)

    # These attributes are set for the worker in bin/worker
    expected_attributes = {
      # Contains a list of all binary checksums seen for this workflow execution
      'BinaryChecksums' => [expected_binary_checksum]
    }.merge(expected_added_attributes)

    execution_info = Temporal.fetch_workflow_execution_info(
      integration_spec_namespace,
      workflow_id,
      nil
    )
    # Temporal might add new built-in search attributes, so just assert that
    # the expected attributes are a subset of the actual attributes:
    expect(execution_info.search_attributes).to be >= expected_attributes
  end
end
