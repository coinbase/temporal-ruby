require 'activities/long_running_activity'

class LongWorkflow < Temporal::Workflow
  def execute(cycles = 10, interval = 1)
    future = LongRunningActivity.execute(cycles, interval, options: { timeouts: { heartbeat: interval * 2 } })

    workflow.on_signal do |signal, input|
      logger.warn "Signal received", { signal: signal, input: input }
      future.cancel
    end

    future.get
  end
end
