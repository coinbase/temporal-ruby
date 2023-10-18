module Temporal
  class Workflow
    class CountWorkflowAggregation
      def initialize(count:)
        @count = count
      end

      attr_reader :count
    end
  end
end
