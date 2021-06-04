# Echoes what you pass in to allow testing returning various types of values from workflows.
class ResultWorkflow < Temporal::Workflow
  def execute(result)
    result
  end
end
