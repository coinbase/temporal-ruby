require 'workflows/simple_timer_workflow'
require 'activities/terminate_workflow_activity'

class ChildWorkflowTerminatedWorkflow < Temporal::Workflow
  def execute
    # start a child workflow that executes for 60 seconds, then attempts to try and terminate that workflow
    result = SimpleTimerWorkflow.execute(60)
    child_workflow_execution = result.child_workflow_execution_future.get
    TerminateWorkflowActivity.execute!(
      'ruby-samples',
      child_workflow_execution.workflow_id,
      child_workflow_execution.run_id
    )

    # check that the result is now 'failed'
    {
      child_workflow_terminated: result.failed?, # terminated is represented as failed? with the Terminated Error
      error: result.get
    }
  end
end
