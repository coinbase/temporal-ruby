require 'temporal/metadata/base'

module Temporal
  module Metadata
    class Activity < Base
      attr_reader :namespace, :id, :name, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name, :headers

      def initialize(namespace:, id:, name:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:, headers: {})
        @namespace = namespace
        @id = id
        @name = name
        @task_token = task_token
        @attempt = attempt
        @workflow_run_id = workflow_run_id
        @workflow_id = workflow_id
        @workflow_name = workflow_name
        @headers = headers

        freeze
      end

      def activity?
        true
      end
    end
  end
end
