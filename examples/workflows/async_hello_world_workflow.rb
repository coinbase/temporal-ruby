require 'activities/hello_world_activity'

class AsyncHelloWorldWorkflow < Cadence::Workflow
  def execute(num)
    futures = num.times.map do |i|
      HelloWorldActivity.execute("param_#{i}")
    end

    workflow.wait_for_all(*futures)
  end
end
