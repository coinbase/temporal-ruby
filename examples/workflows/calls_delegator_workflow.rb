require 'activities/delegator_activity'

class CallsDelegatorWorkflow < Temporal::Workflow

  # In-workflow client to remotely invoke activity.
  def call_executor(executor_class, args)
    # We want temporal to record the MyExecutor class--e.g. 'Plus','Times'--as the name of the activites,
    # rather than DelegatorActivity, for better debuggability
    workflow.execute_activity!(
      executor_class,
      args
    )
  end

  def execute
    operands = { a: 5, b: 3 }
    result_1 = call_executor(Plus, operands)
    result_2 = call_executor(Times, operands)
    { sum: result_1, product: result_2 }
  end
end
