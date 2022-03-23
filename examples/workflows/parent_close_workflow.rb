require 'workflows/slow_child_workflow'

class ParentCloseWorkflow < Temporal::Workflow
  def execute(child_workflow_id, parent_close_policy)
    options = {
      workflow_id: child_workflow_id,
      parent_close_policy: parent_close_policy,
    }
    SlowChildWorkflow.execute(1, options: options)
    return
  end
end
