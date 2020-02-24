require 'activities/hello_world_activity'

class HelloWorldWorkflow < Cadence::Workflow
  def execute
    HelloWorldActivity.execute!('Alice')

    return
  end
end
