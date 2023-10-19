module Temporal
  class Workflow
    class CountWorkflowsResult
      def initialize(count:)
        @count = count
      end

      attr_reader :count
    end
  end
end
