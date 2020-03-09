module Cadence
  module Saga
    class Result
      attr_reader :rollback_reason

      def initialize(completed, rollback_reason = nil)
        @completed = completed
        @rollback_reason = rollback_reason

        freeze
      end

      def completed?
        @completed
      end

      def compensated?
        !completed?
      end
    end
  end
end
