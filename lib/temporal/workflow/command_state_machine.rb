module Temporal
  class Workflow
    class CommandStateMachine
      NEW_STATE = :new
      REQUESTED_STATE = :requested
      SCHEDULED_STATE = :scheduled
      STARTED_STATE = :started
      COMPLETED_STATE = :completed
      CANCELED_STATE = :canceled
      FAILED_STATE = :failed
      TIMED_OUT_STATE = :timed_out
      TERMINATED_STATE = :terminated

      attr_reader :state

      def initialize
        @state = NEW_STATE
      end

      def requested
        @state = REQUESTED_STATE
      end

      def schedule
        @state = SCHEDULED_STATE
      end

      def start
        @state = STARTED_STATE
      end

      def complete
        @state = COMPLETED_STATE
      end

      def cancel
        @state = CANCELED_STATE
      end

      def terminated
        @state = TERMINATED_STATE
      end

      def fail
        @state = FAILED_STATE
      end

      def time_out
        @state = TIMED_OUT_STATE
      end
    end
  end
end
