require 'activities/async_activity'

class AsyncActivityWorkflow < Cadence::Workflow
  def execute
    AsyncActivity.execute!
  end
end
