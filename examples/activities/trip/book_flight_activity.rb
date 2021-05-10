module Trip
  class BookFlightActivity < Temporal::Activity
    def execute(trip_id)
      logger.info "Booking flight", { trip_id: trip_id }

      return { reservation_id: SecureRandom.uuid, total: rand(0..1000) / 10.0 }
    end
  end
end
