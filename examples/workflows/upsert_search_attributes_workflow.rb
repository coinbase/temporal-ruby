require 'activities/hello_world_activity'
class UpsertSearchAttributesWorkflow < Temporal::Workflow
  # time_value example: use this format: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  def execute(string_value, bool_value, float_value, int_value, time_value)
    # These are included in the default temporal docker setup.
    # Run tctl admin cluster get-search-attributes to list the options and
    # See https://docs.temporal.io/docs/tctl/how-to-add-a-custom-search-attribute-to-a-cluster-using-tctl
    # for instructions on adding them.
    attributes = {
      'CustomStringField' => string_value,
      'CustomBoolField' => bool_value,
      'CustomDoubleField' => float_value,
      'CustomIntField' => int_value,
      'CustomDatetimeField' => time_value,
    }
    workflow.upsert_search_attributes(attributes)
    # The following lines are extra complexity to test if upsert_search_attributes is tracked properly in the internal
    # state machine.
    future = HelloWorldActivity.execute("Moon")

    name = workflow.side_effect { SecureRandom.uuid }
    workflow.wait_for_all(future)

    HelloWorldActivity.execute!(name)
    attributes
  end
end
