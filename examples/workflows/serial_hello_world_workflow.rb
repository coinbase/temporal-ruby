require 'activities/hello_world_activity'

class SerialHelloWorldWorkflow < Cadence::Workflow
  def execute(*names)
    names.each do |name|
      HelloWorldActivity.execute!(name)
    end

    return
  end
end
