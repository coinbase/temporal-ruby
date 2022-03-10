require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Activity < Base
      attr_reader :namespace, :id, :name, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name, :headers, :heartbeat_details, :scheduled_time, :current_attempt_scheduled_time

      def initialize(namespace:, id:, name:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:, headers: {}, heartbeat_details:, scheduled_time:, current_attempt_scheduled_time:)
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
        @scheduled_time = scheduled_time
        @current_attempt_scheduled_time = current_attempt_scheduled_time

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
          'scheduled_time' => scheduled_time,
          'current_attempt_scheduled_time' => current_attempt_scheduled_time,
        }
      end
    end
  end
end
