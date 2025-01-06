# frozen_string_literal: true

class TimeskippableWorkflow < Temporal::Workflow

  def execute(timer_timeout)
    begin
      meta = workflow.metadata.to_h
      p "BONK #{timer_timeout} @ #{meta['workflow_id']}"
      timer = workflow.start_timer(timer_timeout)
      unblocked = false
      workflow.on_signal('unblock') do |signal_value|
        unblocked = true
      end
      workflow.wait_until do
        timer.finished? || unblocked
      end
      # timer.cancel if unblocked
      p "HOWDY @ #{meta['workflow_id']} with unblocked(#{unblocked}) and timer(#{timer.finished?}"
      "is unblocked: #{unblocked} and timer is #{timer.finished?}"
    rescue Exception => exception
      p "OH NOES! #{exception.message}"
    end
  end
end

