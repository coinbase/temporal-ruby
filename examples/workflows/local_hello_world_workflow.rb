require 'activities/hello_world_activity'

class LocalHelloWorldWorkflow < Temporal::Workflow
  def execute
    HelloWorldActivity.execute_locally('Alice')
    HelloWorldActivity.execute!('Bob')

    return
  end
end
