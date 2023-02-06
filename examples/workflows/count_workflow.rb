class CountWorkflow < Temporal::Workflow
  def execute
    # do nothing, we just want to run these so we can count them later in an integration test!
    return nil
  end
end
