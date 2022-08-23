class ScheduleChildWorkflow < Temporal::Workflow
  def execute(child_workflow_id, cron_schedule)
    HelloWorldWorkflow.schedule(cron_schedule, options: { workflow_id: child_workflow_id })
    workflow.sleep(1)
  end
end
