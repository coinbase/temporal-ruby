require 'temporal/utils'

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
          workflow_id: response.execution.workflowId,
          run_id: response.execution.run_id,
          start_time: Utils.time_from_nanos(response.startTime),
          close_time: Utils.time_from_nanos(response.closeTime),
          status: response.closeStatus || RUNNING_STATUS,
          history_length: response.historyLength,
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
