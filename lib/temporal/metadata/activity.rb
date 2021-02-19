require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Activity < Base
      attr_reader :namespace, :id, :name, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name, :headers, :heartbeat_details

      def initialize(namespace:, id:, name:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:, headers: {}, heartbeat_details:)
        @namespace = namespace
        @id = id
        @name = name
        @task_token = task_token
        @attempt = attempt
        @workflow_run_id = workflow_run_id
        @workflow_id = workflow_id
        @workflow_name = workflow_name
        @headers = headers
        @heartbeat_details = heartbeat_details

        freeze
      end

      def activity?
        true
      end

      def to_h
        {
          'attempt' => attempt,
          'headers' => headers,
          'heartbeat_details' => heartbeat_details,
          'activity_id' => id,
          'activity_name' => name,
          'namespace' => namespace,
          'task_token' => task_token,
          'workflow_id' => workflow_id,
          'workflow_name' => workflow_name,
          'workflow_run_id' => workflow_run_id
        }
      end
    end
  end
end
