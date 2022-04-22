require 'workflows/slow_child_workflow'

class ParentCloseWorkflow < Temporal::Workflow
  def execute(child_workflow_id, parent_close_policy)
    options = {
      workflow_id: child_workflow_id,
      parent_close_policy: parent_close_policy,
    }
    result = SlowChildWorkflow.execute(1, options: options)
    result.child_workflow_execution_future.get
    return
  end
end
