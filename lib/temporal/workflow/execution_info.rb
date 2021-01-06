module Temporal
  class Workflow
    class ExecutionInfo < Struct.new(:workflow, :workflow_id, :run_id, :start_time, :close_time, :status, :history_length, keyword_init: true)
      RUNNING_STATUS = :RUNNING
      COMPLETED_STATUS = :COMPLETED
      FAILED_STATUS = :FAILED
      CANCELED_STATUS = :CANCELED
      TERMINATED_STATUS = :TERMINATED
      CONTINUED_AS_NEW_STATUS = :CONTINUED_AS_NEW
      TIMED_OUT_STATUS = :TIMED_OUT

      API_STATUS_MAP = {
        WORKFLOW_EXECUTION_STATUS_RUNNING: RUNNING_STATUS,
        WORKFLOW_EXECUTION_STATUS_COMPLETED: COMPLETED_STATUS,
        WORKFLOW_EXECUTION_STATUS_FAILED: FAILED_STATUS,
        WORKFLOW_EXECUTION_STATUS_CANCELED: CANCELED_STATUS,
        WORKFLOW_EXECUTION_STATUS_TERMINATED: TERMINATED_STATUS,
        WORKFLOW_EXECUTION_STATUS_CONTINUED_AS_NEW: CONTINUED_AS_NEW_STATUS,
        WORKFLOW_EXECUTION_STATUS_TIMED_OUT: TIMED_OUT_STATUS
      }.freeze

      VALID_STATUSES = [
        RUNNING_STATUS,
        COMPLETED_STATUS,
        FAILED_STATUS,
        CANCELED_STATUS,
        TERMINATED_STATUS,
        CONTINUED_AS_NEW_STATUS,
        TIMED_OUT_STATUS
      ].freeze

      def self.generate_from(response)
        new(
          workflow: response.type.name,
          workflow_id: response.execution.workflow_id,
          run_id: response.execution.run_id,
          start_time: response.start_time&.to_time,
          close_time: response.close_time&.to_time,
          status: API_STATUS_MAP.fetch(response.status),
          history_length: response.history_length,
        ).freeze
      end

      VALID_STATUSES.each do |status|
        define_method("#{status.downcase}?") do
          self.status == status
        end
      end
    end
  end
end
