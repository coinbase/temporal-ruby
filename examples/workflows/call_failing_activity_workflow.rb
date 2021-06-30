require 'activities/failing_activity'

# exercises a workflow's ability to handle errors in user code, which get
# re-raised in the workflow.
class CallFailingActivityWorkflow < Temporal::Workflow
  def execute(message)
    begin
      FailingActivity.execute!(message)
    rescue => e
      return {class: e.class, message: e.message}
    end
    raise 'Whoops, no error received'
  end
end
