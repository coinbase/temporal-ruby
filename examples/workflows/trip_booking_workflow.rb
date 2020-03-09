require 'cadence/saga/concern'
Dir[File.expand_path('../activities/trip/*.rb', __dir__)].each { |f| require f }

class TripBookingWorkflow < Cadence::Workflow
  include Cadence::Saga::Concern

  def execute(trip_id)
    total = 0

    result = run_saga do |saga|
      car = Trip::RentCarActivity.execute!(trip_id)
      saga.add_compensation(Trip::CancelCarActivity, car[:reservation_id])

      room = Trip::BookHotelActivity.execute!(trip_id)
      saga.add_compensation(Trip::CancelHotelActivity, room[:reservation_id])

      flight = Trip::BookFlightActivity.execute!(trip_id)
      saga.add_compensation(Trip::CancelFlightActivity, flight[:reservation_id])

      total = car[:total] + room[:total] + flight[:total]
      Trip::MakePaymentActivity.execute!(trip_id, total)
    end

    if result.completed?
      return "Total amount paid: #{total}"
    else
      return "Workflow rolled back: #{result.rollback_reason.message}"
    end
  end
end
