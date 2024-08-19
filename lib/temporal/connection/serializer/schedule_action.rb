require "temporal/connection/serializer/base"
require "temporal/concerns/payloads"

module Temporal
  module Connection
    module Serializer
      class ScheduleAction < Base
        def to_proto
          unless object.is_a?(Temporal::Schedule::StartWorkflowAction)
            raise ArgumentError, "Unknown action type #{object.class}"
          end

          Temporalio::Api::Schedule::V1::ScheduleAction.new(
            start_workflow: Temporalio::Api::Workflow::V1::NewWorkflowExecutionInfo.new(
              workflow_id: object.workflow_id,
              workflow_type: Temporalio::Api::Common::V1::WorkflowType.new(
                name: object.name
              ),
              task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(
                name: object.task_queue
              ),
              input: converter.to_payloads(object.input),
              workflow_execution_timeout: object.execution_timeout,
              workflow_run_timeout: object.run_timeout,
              workflow_task_timeout: object.task_timeout,
              header: Temporalio::Api::Common::V1::Header.new(
                fields: converter.to_payload_map(object.headers || {})
              ),
              memo: Temporalio::Api::Common::V1::Memo.new(
                fields: converter.to_payload_map(object.memo || {})
              ),
              search_attributes: Temporalio::Api::Common::V1::SearchAttributes.new(
                indexed_fields: converter.to_payload_map_without_codec(object.search_attributes || {})
              )
            )
          )
        end
      end
    end
  end
end
