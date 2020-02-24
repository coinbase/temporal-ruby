require 'activities/hello_world_activity'

class SideEffectWorkflow < Cadence::Workflow
  def execute
    input_1 = workflow.side_effect { SecureRandom.uuid }
    input_2 = workflow.side_effect { SecureRandom.uuid }

    future_1 = HelloWorldActivity.execute(input_1)
    future_2 = HelloWorldActivity.execute(input_2)

    workflow.wait_for_all(future_1, future_2)
  end
end
