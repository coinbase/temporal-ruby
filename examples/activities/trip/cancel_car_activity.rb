module Trip
  class CancelCarActivity < Cadence::Activity
    def execute(reservation_id)
      logger.info "Cancelling car reservation: #{reservation_id}"

      return
    end
  end
end
