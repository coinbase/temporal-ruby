module Trip
  class BookHotelActivity < Cadence::Activity
    def execute(trip_id)
      logger.info "Booking hotel room for trip #{trip_id}"

      return { reservation_id: SecureRandom.uuid, total: rand(0..1000) / 10.0 }
    end
  end
end
