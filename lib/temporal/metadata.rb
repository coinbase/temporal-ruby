require 'temporal/errors'
require 'temporal/metadata/activity'
require 'temporal/metadata/workflow'
require 'temporal/metadata/workflow_task'

module Temporal
  module Metadata
    ACTIVITY_TYPE = :activity
    WORKFLOW_TASK_TYPE = :workflow_task
    WORKFLOW_TYPE = :workflow

    class << self
      def generate(type, data, namespace = nil)
        case type
        when ACTIVITY_TYPE
          activity_metadata_from(data, namespace)
        when WORKFLOW_TASK_TYPE
          workflow_task_metadata_from(data, namespace)
        when WORKFLOW_TYPE
          workflow_metadata_from(data)
        else
          raise InternalError, 'Unsupported metadata type'
        end
      end

      private

      def headers(fields)
        result = {}
        fields.each do |field, payload|
          result[field] = Temporal.configuration.converter.from_payload(payload)
        end
        result
      end

      def activity_metadata_from(task, namespace)
        Metadata::Activity.new(
          namespace: namespace,
          id: task.activity_id,
          name: task.activity_type.name,
          task_token: task.task_token,
          attempt: task.attempt,
          workflow_run_id: task.workflow_execution.run_id,
          workflow_id: task.workflow_execution.workflow_id,
          workflow_name: task.workflow_type.name,
          headers: headers(task.header&.fields),
          heartbeat_details: Temporal.configuration.converter.from_payloads(task.heartbeat_details)
        )
      end

      def workflow_task_metadata_from(task, namespace)
        Metadata::WorkflowTask.new(
          namespace: namespace,
          id: task.started_event_id,
          task_token: task.task_token,
          attempt: task.attempt,
          workflow_run_id: task.workflow_execution.run_id,
          workflow_id: task.workflow_execution.workflow_id,
          workflow_name: task.workflow_type.name
        )
      end

      def workflow_metadata_from(event)
        Metadata::Workflow.new(
          name: event.workflow_type.name,
          run_id: event.original_execution_run_id,
          attempt: event.attempt,
          headers: headers(event.header&.fields)
        )
      end
    end
  end
end
