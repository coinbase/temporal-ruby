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
          headers: headers(task.header&.fields),
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

      # @param event [Temporal::Workflow::History::Event] Workflow started history event
      # @param task_metadata [Temporal::Metadata::WorkflowTask] workflow task metadata
      def generate_workflow_metadata(event, task_metadata)
        Metadata::Workflow.new(
          name: event.workflow_type.name,
          id: task_metadata.workflow_id,
          run_id: event.original_execution_run_id,
          attempt: event.attempt,
          namespace: task_metadata.namespace,
          task_queue: event.task_queue.name,
          headers: headers(event.header&.fields),
        )
      end

      private

      def headers(fields)
        result = {}
        fields.each do |field, payload|
          result[field] = from_payload(payload)
        end
        result
      end
    end
  end
end
