require 'activities/delegator_activity'

class CallsDelegatorWorkflow < Temporal::Workflow
  def execute
    operands = { a: 5, b: 3 }
    result_1 = Plus.call(operands)
    result_2 = Times.call(operands)
    { sum: result_1, product: result_2 }
  end
end
