require 'activities/hello_world_activity'

class HelloWorldWorkflow < Temporal::Workflow
  def execute(name = 'Alice')
    return HelloWorldActivity.execute!(name)
  end
end
