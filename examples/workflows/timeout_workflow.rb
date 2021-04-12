require 'activities/sleep_activity'

class TimeoutWorkflow < Temporal::Workflow
  # Test workflow timeouts by setting workflow sleep.
  # Test activity timeouts by setting activity_sleep > 5.
  timeouts execution: 20, run: 5, task: 1

  def execute(workflow_sleep, activity_sleep)
    sleep(workflow_sleep)
    SleepActivity.execute!(activity_sleep)
  end
end
