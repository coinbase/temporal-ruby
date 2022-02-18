require 'temporal/metadata/base'

module Temporal
  module Metadata
    class WorkflowTask < Base
      attr_reader :namespace, :id, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name, :query_type, :query_args

      def initialize(namespace:, id:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:, query_type:, query_args:)
        @namespace = namespace
        @id = id
        @task_token = task_token
        @attempt = attempt
        @workflow_run_id = workflow_run_id
        @workflow_id = workflow_id
        @workflow_name = workflow_name
        @query_type = query_type
        @query_args = query_args

        freeze
      end

      def workflow_task?
        true
      end

      def to_h
        {
          'namespace' => namespace,
          'workflow_task_id' => id,
          'workflow_name' => workflow_name,
          'workflow_id' => workflow_id,
          'workflow_run_id' => workflow_run_id,
          'query_type' => query_type,
          'query_args' => query_args,
          'attempt' => attempt
        }
      end
    end
  end
end
