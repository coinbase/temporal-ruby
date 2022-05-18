require 'workflows/slow_child_workflow'

class StartChildWorkflowWorkflow < Temporal::Workflow
  def execute(child_workflow_id)
    options = {
      workflow_id: child_workflow_id,
      parent_close_policy: :abandon,
    }
    result = SlowChildWorkflow.execute(1, options: options)
    child_workflow_execution = result.child_workflow_execution_future.get

    # return back the workflow_id and run_id so we can nicely check if
    # everything was passed correctly
    response = Struct.new(:workflow_id, :run_id)
    response.new(child_workflow_execution.workflow_id, child_workflow_execution.run_id)
  end
end
