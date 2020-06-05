module Trip
  class CancelHotelActivity < Temporal::Activity
    def execute(reservation_id)
      logger.info "Cancelling hotel reservation: #{reservation_id}"

      return
    end
  end
end
