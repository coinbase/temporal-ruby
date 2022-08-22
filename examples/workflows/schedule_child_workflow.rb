class ScheduleChildWorkflow < Temporal::Workflow
  def execute(child_workflow_id, cron_schedule)
    state = "started"
    workflow.on_signal("finish") do
      state = "finished"
    end

    HelloWorldWorkflow.schedule(cron_schedule, options: { workflow_id: child_workflow_id })
    workflow.wait_until { state == "finished" }

    {
      state: state
    }
  end
end
