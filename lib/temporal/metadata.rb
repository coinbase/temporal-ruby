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
          heartbeat_details: from_details_payloads(task.heartbeat_details)
        )
      end

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

      # event: WorkflowExecutionStartedEventAttributes
      # task_metadata: Temporal::Metadata::WorkflowTask
      def generate_workflow_metadata(event, task_metadata)
        Metadata::Workflow.new(
          name: event.workflow_type.name,
          workflow_id: task_metadata.workflow_id,
          run_id: event.original_execution_run_id,
          attempt: event.attempt,
          namespace: task_metadata.namespace,
          headers: from_payload_map(event.header&.fields || {}),
          task_queue: event.task_queue.name,
          memo: from_payload_map(event.memo&.fields || {}),
        )
      end
    end
  end
end
