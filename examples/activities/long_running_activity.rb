class LongRunningActivity < Temporal::Activity
  class Canceled < Temporal::ActivityException; end

  def execute(cycles, interval)
    cycles.times do
      response = activity.heartbeat

      if response.cancel_requested
        raise Canceled, 'cancel activity request received'
      end

      sleep interval
    end

    return
  end
end
