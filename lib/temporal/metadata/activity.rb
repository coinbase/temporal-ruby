require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Activity < Base
      attr_reader :namespace, :id, :name, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name, :headers, :heartbeat_details, :scheduled_at, :current_attempt_scheduled_at, :heartbeat_timeout

      def initialize(namespace:, id:, name:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:, headers: {}, heartbeat_details:, scheduled_at:, current_attempt_scheduled_at:, heartbeat_timeout:)
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
        @scheduled_at = scheduled_at
        @current_attempt_scheduled_at = current_attempt_scheduled_at
        @heartbeat_timeout = heartbeat_timeout

        freeze
      end

      def activity?
        true
      end

      def to_h
        {
          'namespace' => namespace,
          'workflow_id' => workflow_id,
          'workflow_name' => workflow_name,
          'workflow_run_id' => workflow_run_id,
          'activity_id' => id,
          'activity_name' => name,
          'attempt' => attempt,
          'scheduled_at' => scheduled_at.to_s,
          'current_attempt_scheduled_at' => current_attempt_scheduled_at.to_s
        }
      end
    end
  end
end
