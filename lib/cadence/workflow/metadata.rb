module Cadence
  class Workflow
    class Metadata
      attr_reader :run_id, :attempt, :headers

      def self.from_event(attributes)
        new(
          run_id: attributes.originalExecutionRunId,
          attempt: attributes.attempt,
          headers: attributes.header&.fields || {}
        )
      end

      def initialize(run_id:, attempt:, headers: {})
        @run_id = run_id
        @attempt = attempt
        @headers = headers

        freeze
      end
    end
  end
end
