require 'activities/hello_world_activity'

class HelloWorldWorkflow < Temporal::Workflow
  def execute
    HelloWorldActivity.execute!('Alice')

    return
  end
end
