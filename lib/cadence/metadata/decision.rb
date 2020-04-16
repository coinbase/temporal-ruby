require 'cadence/metadata/base'

module Cadence
  module Metadata
    class Decision < Base
      attr_reader :domain, :id, :task_token, :attempt, :workflow_run_id, :workflow_id, :workflow_name

      def initialize(domain:, id:, task_token:, attempt:, workflow_run_id:, workflow_id:, workflow_name:)
        @domain = domain
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
