require 'cadence/metadata/base'

module Cadence
  module Metadata
    class Decision < Base
      attr_reader :id, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name

      def initialize(id:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:)
        @id = id
        @task_token = task_token
        @attempt = attempt
        @workflow_run_id = workflow_run_id
        @workflow_id = workflow_id
        @workflow_name = workflow_name

        freeze
      end

      def decision?
        true
      end
    end
  end
end
