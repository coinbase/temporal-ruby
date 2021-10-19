require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Workflow < Base
      attr_reader :name, :workflow_id, :run_id, :attempt, :headers, :namespace, :task_queue, :memo, :run_started_at

      def initialize(name:, workflow_id:, run_id:, attempt:, headers:, namespace:, task_queue:, memo:, run_started_at:)
        @name = name
        @workflow_id = workflow_id
        @run_id = run_id
        @attempt = attempt
        @namespace = namespace
        @task_queue = task_queue
        @headers = headers
        @memo = memo
        @run_started_at = run_started_at
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
          'task_queue' => task_queue,
          'memo' => memo,
          'run_started_at' => run_started_at.to_f,
        }
      end
    end
  end
end
