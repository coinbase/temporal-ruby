# frozen_string_literal: true

class TimeskippableWorkflow < Temporal::Workflow

  def execute(timer_timeout)
    timer = workflow.start_timer(timer_timeout)
    unblocked = false
    workflow.on_signal('unblock') do |signal_value|
      unblocked = true
    end
    workflow.wait_until do
      timer.finished? || unblocked
    end
    timer.cancel if unblocked
    "unblocked:#{unblocked};timer:#{timer.finished?}"
  end
end

