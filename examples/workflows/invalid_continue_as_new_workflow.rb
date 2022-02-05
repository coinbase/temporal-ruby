require 'activities/hello_world_activity'

# If you run this, you'll get a TryingToCompleteWorkflowError because after the 
# continue_as_new, we try to do something else.
class InvalidContinueAsNewWorkflow < Temporal::Workflow
  timeouts execution: 20

  def execute
    future = HelloWorldActivity.execute('Alice')
    workflow.sleep(1)
    workflow.continue_as_new
    # Doing anything after continue_as_new (or any workflow completion) is illegal
    future.done do 
      HelloWorldActivity.execute('Bob')
    end
  end
end
