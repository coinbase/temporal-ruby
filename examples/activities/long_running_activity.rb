class LongRunningActivity < Cadence::Activity
  class Canceled < Cadence::ActivityException; end

  def execute(cycles, interval)
    cycles.times do
      response = activity.heartbeat

      if response.cancelRequested
        raise Canceled, 'cancel activity request received'
      end

      sleep interval
    end

    return
  end
end
