require 'activities/hello_world_activity'
class UpsertSearchAttributesWorkflow < Temporal::Workflow
  # time_value example: use this format: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  # values comes from keyword args passed to start_workflow
  def execute(values)
    # These are included in the default temporal docker setup.
    # Run tctl admin cluster get-search-attributes to list the options and
    # See https://docs.temporal.io/docs/tctl/how-to-add-a-custom-search-attribute-to-a-cluster-using-tctl
    # for instructions on adding them.
    attributes = {
      'CustomStringField' => values[:string_value],
      'CustomBoolField' => values[:bool_value],
      'CustomDoubleField' => values[:float_value],
      'CustomIntField' => values[:int_value],
      'CustomDatetimeField' => values[:time_value],
    }
    attributes.compact!
    workflow.upsert_search_attributes(attributes)
    # .dup because the same backing hash may be used throughout the workflow, causing
    # the equality check at the end to succeed incorrectly
    attributes_after_upsert = workflow.search_attributes.dup

    # The following lines are extra complexity to test if upsert_search_attributes is tracked properly in the internal
    # state machine.
    future = HelloWorldActivity.execute("Moon")

    name = workflow.side_effect { SecureRandom.uuid }
    workflow.wait_for_all(future)

    HelloWorldActivity.execute!(name)

    attributes_at_end = workflow.search_attributes
    if attributes_at_end != attributes_after_upsert
      raise "Attributes at end #{attributes_at_end} don't match after upsert #{attributes_after_upsert}"
    end

    attributes_at_end
  end
end
