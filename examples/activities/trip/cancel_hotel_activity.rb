module Trip
  class CancelHotelActivity < Cadence::Activity
    def execute(reservation_id)
      logger.info "Cancelling hotel reservation: #{reservation_id}"

      return
    end
  end
end
