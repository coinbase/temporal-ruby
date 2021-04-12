require 'activities/hello_world_activity'

class LoopWorkflow < Temporal::Workflow
  def execute(count)
    HelloWorldActivity.execute!('Alice')

    if count > 1
      return workflow.continue_as_new(LoopWorkflow, count - 1)
    end

    return
  end
end
