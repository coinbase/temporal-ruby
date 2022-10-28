class TerminateWorkflowActivity < Temporal::Activity
  def execute(namespace, workflow_id, run_id)
    Temporal.terminate_workflow(workflow_id, namespace: namespace, run_id: run_id)
  end
end
