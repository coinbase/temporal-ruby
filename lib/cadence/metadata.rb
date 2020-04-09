require 'cadence/errors'
require 'cadence/metadata/activity'
require 'cadence/metadata/decision'
require 'cadence/metadata/workflow'

module Cadence
  module Metadata
    ACTIVITY_TYPE = :activity
    DECISION_TYPE = :decision
    WORKFLOW_TYPE = :workflow

    class << self
      def generate(type, data)
        case type
        when ACTIVITY_TYPE
          activity_metadata_from(data)
        when DECISION_TYPE
          decision_metadata_from(data)
        when WORKFLOW_TYPE
          workflow_metadata_from(data)
        else
          raise InternalError, 'Unsupported metadata type'
        end
      end

      private

      def activity_metadata_from(task)
        Metadata::Activity.new(
          id: task.activityId,
          name: task.activityType.name,
          task_token: task.taskToken,
          attempt: task.attempt,
          workflow_run_id: task.workflowExecution.runId,
          workflow_id: task.workflowExecution.workflowId,
          workflow_name: task.workflowType.name,
          headers: task.header&.fields || {}
        )
      end

      def decision_metadata_from(task)
        Metadata::Decision.new(
          id: task.startedEventId,
          task_token: task.taskToken,
          attempt: task.attempt,
          workflow_run_id: task.workflowExecution.runId,
          workflow_id: task.workflowExecution.workflowId,
          workflow_name: task.workflowType.name
        )
      end

      def workflow_metadata_from(event)
        Metadata::Workflow.new(
          name: event.workflowType.name,
          run_id: event.originalExecutionRunId,
          attempt: event.attempt,
          headers: event.header&.fields || {}
        )
      end
    end
  end
end
