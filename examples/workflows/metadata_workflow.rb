class MetadataWorkflow < Temporal::Workflow
  def execute
    workflow.metadata
  end
end
