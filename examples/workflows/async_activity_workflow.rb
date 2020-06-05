require 'activities/async_activity'

class AsyncActivityWorkflow < Temporal::Workflow
  def execute
    AsyncActivity.execute!
  end
end
