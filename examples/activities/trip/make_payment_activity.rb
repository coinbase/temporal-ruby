module Trip
  class MakePaymentActivity < Temporal::Activity
    class InsufficientFunds < Temporal::ActivityException; end

    def execute(trip_id, total)
      logger.info "Processing payment for #{total} (trip_id #{trip_id})"

      raise InsufficientFunds, "Unable to charge #{total}"
    end
  end
end
