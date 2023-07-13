require 'workflows/upsert_search_attributes_workflow'
require 'time'

describe 'starting workflow with initial search attributes', :integration do
  it 'has attributes appear in final execution info, but can get overriden by upserting' do
    workflow_id = 'initial_search_attributes_test_wf-' + SecureRandom.uuid
    expected_binary_checksum = `git show HEAD -s --format=%H`.strip

    initial_search_attributes = {
      'CustomBoolField' => false,
      'CustomIntField' => -1,
      'CustomDatetimeField' => Time.now,

      # These should get overriden when the workflow upserts them
      'CustomStringField' => 'meow',
      'CustomDoubleField' => 6.28,
    }
    # Override some of the initial search attributes by upserting them during the workflow execution.
    upserted_search_attributes = {
      'CustomStringField' => 'moo',
      'CustomDoubleField' => 3.14,
    }
    expected_custom_attributes = initial_search_attributes.merge(upserted_search_attributes)
    # Datetime fields get converted to the Time#iso8601 format, in UTC
    expected_custom_attributes['CustomDatetimeField'] = expected_custom_attributes['CustomDatetimeField'].utc.iso8601

    run_id = Temporal.start_workflow(
      UpsertSearchAttributesWorkflow,
      string_value: upserted_search_attributes['CustomStringField'],
      float_value: upserted_search_attributes['CustomDoubleField'],
      # Don't upsert anything for the bool, int, or time search attributes;
      # their values should be the initial ones set when first starting the workflow.
      bool_value: nil,
      int_value: nil,
      time_value: nil,
      options: {
        workflow_id: workflow_id,
        search_attributes: initial_search_attributes,
      },
    )

    # UpsertSearchAttributesWorkflow returns the search attributes it upserted during its execution
    attributes_at_end = Temporal.await_workflow_result(
      UpsertSearchAttributesWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    expect(attributes_at_end).to eq(expected_custom_attributes)

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
    # Temporal might add new built-in search attributes, so just assert that
    # the expected attributes are a subset of the actual attributes:
    expect(execution_info.search_attributes).to be >= expected_attributes
  end
end
