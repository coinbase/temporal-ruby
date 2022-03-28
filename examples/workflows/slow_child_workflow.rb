class SlowChildWorkflow < Temporal::Workflow
  def execute(delay)
    if delay.positive?
      workflow.sleep(delay)
    end

    return { parent_workflow_id: workflow.metadata.parent_id }
  end
end
