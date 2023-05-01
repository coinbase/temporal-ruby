require 'activities/long_running_activity'

class LongWorkflow < Temporal::Workflow
  def execute(cycles = 10, interval = 1, activity_start_to_close_timeout = 30)
    future = LongRunningActivity.execute(
      cycles,
      interval,
      options: {
        timeouts: {
          heartbeat: interval * 2,
          start_to_close: activity_start_to_close_timeout
        }
      })

    workflow.on_signal do |signal, input|
      logger.warn "Signal received", { signal: signal, input: input }
      future.cancel
    end

    future.get
  end
end
