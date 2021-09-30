require 'activities/hello_world_activity'

class AsyncTimerWorkflow < Temporal::Workflow
  def execute
    timer = workflow.start_timer(30)
    timer.done do
      logger.info('Timer fired!')
      HelloWorldActivity.execute!('timer')
    end

    workflow.wait_for(timer)
  end
end