class UpdatableTimer < Temporal::Workflow
  def execute(sleep_duration)
    started_at = workflow.now
    execute_in_timer(workflow, sleep_duration) do
      workflow.logger.info('Executing workflow')
      workflow.now - started_at
    end
  end

  def execute_in_timer(workflow, sleep_duration, &blk)
    signal_received = false

    workflow.on_signal('update_timer') do |new_duration|
      workflow.logger.info("Received update_timer signal with new duration: #{new_duration}")
      sleep_duration = new_duration
      signal_received = true
    end

    while sleep_duration > 0
      signal_received = false

      timer = workflow.start_timer(sleep_duration)
      workflow.logger.info("Started timer with duration: #{sleep_duration}s")

      workflow.wait_until do
        timer.finished? || signal_received
      end

      if timer.finished?
        workflow.logger.info("Timer fired")
        break
      end

      timer.cancel
    end

    yield
  end
end
