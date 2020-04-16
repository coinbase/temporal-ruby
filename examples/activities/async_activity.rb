class AsyncActivity < Cadence::Activity
  timeouts start_to_close: 120

  def execute
    logger.warn "run `bin/activity complete #{activity.async_token}` to complete activity"

    activity.async
  end
end
