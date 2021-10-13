require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Workflow < Base
      attr_reader :name, :workflow_id, :run_id, :attempt, :headers, :namespace, :task_queue, :memo

      def initialize(name:, workflow_id:, run_id:, attempt:, namespace:, task_queue:, headers: {}, memo: {})
        @name = name
        @workflow_id = workflow_id
        @run_id = run_id
        @attempt = attempt
        @namespace = namespace
        @task_queue = task_queue
        @headers = headers
        @memo = memo
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
        }
      end
    end
  end
end
