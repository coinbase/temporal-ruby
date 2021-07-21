require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Workflow < Base
      attr_reader :name, :workflow_id, :run_id, :attempt, :headers, :namespace

      def initialize(name:, workflow_id:, run_id:, attempt:, namespace:, headers: {})
        @name = name
        @workflow_id = workflow_id
        @run_id = run_id
        @attempt = attempt
        @namespace = namespace
        @headers = headers
        freeze
      end

      def workflow?
        true
      end

      def to_h
        {
          'workflow_name' => name,
          'workflow_id' => workflow_id,
          'run_id' => run_id,
          'attempt' => attempt,
          'namespace' => namespace,
        }
      end
    end
  end
end
