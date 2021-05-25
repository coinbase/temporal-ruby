module Trip
  class CancelFlightActivity < Temporal::Activity
    def execute(reservation_id)
      logger.info "Cancelling flight reservation", { reservation_id: reservation_id }

      return
    end
  end
end
