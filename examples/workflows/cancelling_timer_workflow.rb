require 'activities/sleep_activity'
require 'activities/hello_world_activity'

class CancellingTimerWorkflow < Cadence::Workflow
  def execute(activity_timeout, timer_timeout)
    timer = workflow.start_timer(timer_timeout)
    activity = SleepActivity.execute(activity_timeout)
    timer_fired = false

    timer.done do
      timer_fired = true
      HelloWorldActivity.execute!('extra')
    end

    activity.get

    timer.cancel unless timer_fired

    return
  end
end
