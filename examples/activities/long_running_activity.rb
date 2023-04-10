class LongRunningActivity < Temporal::Activity
  class Canceled < Temporal::ActivityException; end

  def execute(cycles, interval)
    cycles.times do
      # To detect if the activity has been canceled, you can check activity.cancel_requested or
      # simply heartbeat in which case an ActivityCanceled error will be raised. Cancellation
      # is only detected through heartbeating, but the setting of this bit can be delayed by
      # heartbeat throttling which sends the heartbeat on a background thread.
      activity.logger.info("activity.cancel_requested: #{activity.cancel_requested}")

      activity.heartbeat
      if activity.cancel_requested
        raise Canceled, 'cancel activity request received'
      end

      sleep interval
    end

    return
  end
end
