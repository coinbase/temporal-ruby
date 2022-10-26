require 'workflows/quick_timeout_workflow'

class ChildWorkflowTimeoutWorkflow < Temporal::Workflow
  def execute
    # workflow timesout before it can finish running, we should be able to detect that with .failed?
    result = QuickTimeoutWorkflow.execute

    result.get # wait for the workflow to finish so we can detect if it failed or not

    {
      child_workflow_failed: result.failed?,
      error: result.get
    }
  end
end
