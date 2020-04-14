require 'workflows/hello_world_workflow'
require 'activities/hello_world_activity'

class ParentWorkflow < Cadence::Workflow
  def execute
    HelloWorldWorkflow.execute!
    HelloWorldActivity.execute!('Bob')

    return
  end
end
