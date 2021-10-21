require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Workflow < Base
      attr_reader :namespace, :id, :name, :run_id, :attempt, :headers

      def initialize(namespace:, id:, name:, run_id:, attempt:, headers: {})
        @namespace = namespace
        @id = id
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
          'namespace' => namespace,
          'workflow_id' => id,
          'workflow_name' => name,
          'workflow_run_id' => run_id,
          'attempt' => attempt
        }
      end
    end
  end
end
