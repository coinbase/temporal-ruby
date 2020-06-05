require 'activities/hello_world_activity'

class SimpleTimerWorkflow < Temporal::Workflow
  def execute(timeout)
    workflow.sleep(timeout)

    HelloWorldActivity.execute!('yay')

    return
  end
end
