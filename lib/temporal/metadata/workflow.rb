require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Workflow < Base
      attr_reader :namespace, :id, :name, :run_id, :attempt, :task_queue, :headers

      def initialize(namespace:, id:, name:, run_id:, attempt:, task_queue:, headers: {})
        @namespace = namespace
        @id = id
        @name = name
        @run_id = run_id
        @attempt = attempt
        @task_queue = task_queue
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
          'attempt' => attempt,
          'task_queue' => task_queue,
        }
      end
    end
  end
end
