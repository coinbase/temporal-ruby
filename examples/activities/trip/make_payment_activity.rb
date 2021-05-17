module Trip
  class MakePaymentActivity < Temporal::Activity
    class InsufficientFunds < Temporal::ActivityException; end

    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3,
      non_retriable_errors: [InsufficientFunds]
    )

    def execute(trip_id, total)
      logger.info "Processing payment", { amount: total, trip_id: trip_id }

      raise InsufficientFunds, "Unable to charge: #{total}"
    end
  end
end
