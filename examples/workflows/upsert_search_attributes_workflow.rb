class UpsertSearchAttributesWorkflow < Temporal::Workflow
  def execute(string_value, bool_value, float_value, int_value)
    # These are included in the default temporal docker setup.
    # Run tctl admin cluster get-search-attributes to list the options and
    # See https://docs.temporal.io/docs/tctl/how-to-add-a-custom-search-attribute-to-a-cluster-using-tctl
    # for instructions on adding them.
    attributes = { 
      'CustomStringField' => string_value,
      'CustomBoolField' => bool_value,
      'CustomDoubleField' => float_value,
      'CustomIntField' => int_value,
    }
    workflow.upsert_search_attributes(attributes)

    attributes
  end
end
