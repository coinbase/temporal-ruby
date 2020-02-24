module Trip
  class CancelFlightActivity < Cadence::Activity
    def execute(reservation_id)
      logger.info "Cancelling flight reservation: #{reservation_id}"

      return
    end
  end
end
