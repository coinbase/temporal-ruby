class LongRunningActivity < Temporal::Activity
  class Canceled < Temporal::ActivityException; end
  class ShuttingDown < Temporal::ActivityException; end

  def execute(cycles, interval, raise_on_heartbeat)
    cycles.times do
      if raise_on_heartbeat
        # Setting this will cause heartbeat to automatically raise exceptions
        # for all the cases below. This is a convenient way to handle activity
        # interruption in most cases.
        activity.heartbeat_interrupted
      else
        if activity.shutting_down?
          # This error will be reported to Temporal server for this activity. It is also
          # possible to return a success for this activity, in which case it will not be
          # retried.
          raise ShuttingDown, 'worker is shutting down'
        end

        if activity.timed_out?
          # Because the activity has timed out, any success or failure result will be rejected by
          # Temporal server. You will see a GRPC::NotFound error in your logs with a message like
          # "invalid activityID or activity already timed out or invoking workflow is completed"
          # after this activity returns or raises, and temporal-ruby attempts to report it. Do
          # be aware that while this code is running, another attempt of your activity could already
          # have started if the retry policy allows it.
          logger.warn('Activity has timed out')

          return
        end

        # To detect if the activity has been canceled, you can check activity.cancel_requested or
        # simply heartbeat in which case an ActivityCanceled error will be raised. Cancellation
        # is only detected through heartbeating, but the setting of this bit can be delayed by
        # heartbeat throttling which sends the heartbeat on a background thread.
        activity.logger.info("activity.cancel_requested: #{activity.cancel_requested}")

        activity.heartbeat

        # Activity cancellation because the workflow canceled the activity or because the workflow
        # was terminated, is only communicated back to the activity by heartbeating.
        if activity.cancel_requested
          raise Canceled, 'cancel activity request received'
        end
      end

      sleep interval
    end

    return
  end
end
