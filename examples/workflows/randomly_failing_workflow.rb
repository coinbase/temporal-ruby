require 'activities/randomly_failing_activity'

class RandomlyFailingWorkflow < Temporal::Workflow
  def execute
    RandomlyFailingActivity.execute!

    return 'You are very lucky!'
  rescue RandomlyFailingActivity::WrongGuess => e
    return e.message
  end
end
