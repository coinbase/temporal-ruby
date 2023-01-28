require 'activities/failing_with_structured_error_activity'

class HandlingStructuredErrorWorkflow < Temporal::Workflow

  def execute(foo, bar)
    begin
      FailingWithStructuredErrorActivity.execute!(foo, bar)
    rescue FailingWithStructuredErrorActivity::MyError => e
      if e.foo == foo && e.bar == bar
        return 'successfully handled error'
      else
        raise "Failure: didn't receive expected error from the activity"
      end
    end
    raise "Failure: didn't receive any error from the activity"
  end
end
