class SignalWorkflow < Temporal::Workflow
  def execute(sleep_for)
    score = 0
    workflow.on_signal('score') do |signal_value|
      score += signal_value
    end

    workflow.sleep(sleep_for)

    score
  end
end
