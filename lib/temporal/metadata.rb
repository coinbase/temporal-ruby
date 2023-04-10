require 'temporal/errors'
require 'temporal/metadata/activity'
require 'temporal/metadata/workflow'
require 'temporal/metadata/workflow_task'
require 'temporal/concerns/payloads'

module Temporal
  module Metadata

    class << self
      include Concerns::Payloads

      def generate_activity_metadata(task, namespace)
        Metadata::Activity.new(
          namespace: namespace,
          id: task.activity_id,
          name: task.activity_type.name,
          task_token: task.task_token,
          attempt: task.attempt,
          workflow_run_id: task.workflow_execution.run_id,
          workflow_id: task.workflow_execution.workflow_id,
          workflow_name: task.workflow_type.name,
          headers: from_payload_map(task.header&.fields || {}),
          heartbeat_details: from_details_payloads(task.heartbeat_details),
          scheduled_at: task.scheduled_time.to_time,
          current_attempt_scheduled_at: task.current_attempt_scheduled_time.to_time,
          heartbeat_timeout: task.heartbeat_timeout.seconds
        )
      end

      # @param task [Temporalio::Api::WorkflowService::V1::PollWorkflowTaskQueueResponse]
      # @param namespace [String]
      def generate_workflow_task_metadata(task, namespace)
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

      # @param event [Temporal::Workflow::History::Event] Workflow started history event
      # @param task_metadata [Temporal::Metadata::WorkflowTask] workflow task metadata
      def generate_workflow_metadata(event, task_metadata)
        Metadata::Workflow.new(
          name: event.attributes.workflow_type.name,
          id: task_metadata.workflow_id,
          run_id: event.attributes.original_execution_run_id,
          parent_id: event.attributes.parent_workflow_execution&.workflow_id,
          parent_run_id: event.attributes.parent_workflow_execution&.run_id,
          attempt: event.attributes.attempt,
          namespace: task_metadata.namespace,
          task_queue: event.attributes.task_queue.name,
          headers: from_payload_map(event.attributes.header&.fields || {}),
          run_started_at: event.timestamp,
          memo: from_payload_map(event.attributes.memo&.fields || {}),
        )
      end
    end
  end
end
