require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Workflow < Base
      attr_reader :name, :run_id, :attempt, :headers

      def initialize(name:, run_id:, attempt:, headers: {})
        @name = name
        @run_id = run_id
        @attempt = attempt
        @headers = headers

        freeze
      end

      def workflow?
        true
      end

      def to_h
        {
          'attempt' => attempt,
          'headers' => headers,
          'workflow_name' => name,
          'workflow_run_id' => run_id
        }
      end
    end
  end
end
