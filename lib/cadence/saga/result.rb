module Cadence
  module Saga
    class Result
      def initialize(completed, rollback_reason = nil)
        @completed = completed
        @rollback_reason = rollback_reason
      end

      def completed?
        @completed
      end

      def compensated?
        !completed?
      end

      def rollback_reason
        @rollback_reason
      end
    end
  end
end
