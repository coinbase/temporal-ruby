require 'activities/random_number_activity'
require 'activities/hello_world_activity'

class BranchingWorkflow < Cadence::Workflow
  def execute
    random_number = RandomNumberActivity.execute!(max: 100)

    if random_number > 50
      HelloWorldActivity.execute!('top half')
    else
      HelloWorldActivity.execute!('bottom half')
    end

    return "Number picked was: #{random_number}"
  end
end
