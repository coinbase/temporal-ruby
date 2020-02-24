require 'activities/sleep_activity'

class TimeoutWorkflow < Cadence::Workflow
  timeouts execution: 20, task: 1

  def execute(timeout)
    SleepActivity.execute!(timeout)
  end
end
