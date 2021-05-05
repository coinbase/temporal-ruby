module Trip
  class BookHotelActivity < Temporal::Activity
    def execute(trip_id)
      logger.info "Booking hotel room", { trip_id: trip_id }

      return { reservation_id: SecureRandom.uuid, total: rand(0..1000) / 10.0 }
    end
  end
end
