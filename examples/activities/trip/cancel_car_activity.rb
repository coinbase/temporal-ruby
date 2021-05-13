module Trip
  class CancelCarActivity < Temporal::Activity
    def execute(reservation_id)
      logger.info "Cancelling car reservation", { reservation_id: reservation_id }

      return
    end
  end
end
