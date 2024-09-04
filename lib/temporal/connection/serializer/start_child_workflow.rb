require 'temporal/connection/serializer/base'
require 'temporal/connection/serializer/retry_policy'
require 'temporal/connection/serializer/workflow_id_reuse_policy'

module Temporal
  module Connection
    module Serializer
      class StartChildWorkflow < Base
        PARENT_CLOSE_POLICY = {
          terminate: Temporalio::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_TERMINATE,
          abandon: Temporalio::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_ABANDON,
          request_cancel: Temporalio::Api::Enums::V1::ParentClosePolicy::PARENT_CLOSE_POLICY_REQUEST_CANCEL,
        }.freeze

        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_START_CHILD_WORKFLOW_EXECUTION,
            start_child_workflow_execution_command_attributes:
              Temporalio::Api::Command::V1::StartChildWorkflowExecutionCommandAttributes.new(
                namespace: object.namespace,
                workflow_id: object.workflow_id.to_s,
                workflow_type: Temporalio::Api::Common::V1::WorkflowType.new(name: object.workflow_type),
                task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(name: object.task_queue),
                input: converter.to_payloads(object.input),
                workflow_execution_timeout: object.timeouts[:execution],
                workflow_run_timeout: object.timeouts[:run],
                workflow_task_timeout: object.timeouts[:task],
                retry_policy: Temporal::Connection::Serializer::RetryPolicy.new(object.retry_policy, converter).to_proto,
                parent_close_policy: serialize_parent_close_policy(object.parent_close_policy),
                header: serialize_headers(object.headers),
                cron_schedule: object.cron_schedule,
                memo: serialize_memo(object.memo),
                workflow_id_reuse_policy: Temporal::Connection::Serializer::WorkflowIdReusePolicy.new(object.workflow_id_reuse_policy, converter).to_proto,
                search_attributes: serialize_search_attributes(object.search_attributes),
              )
          )
        end

        private

        def serialize_headers(headers)
          return unless headers

          Temporalio::Api::Common::V1::Header.new(fields: converter.to_payload_map(headers))
        end

        def serialize_memo(memo)
          return unless memo

          Temporalio::Api::Common::V1::Memo.new(fields: converter.to_payload_map(memo))
        end

        def serialize_parent_close_policy(parent_close_policy)
          return unless parent_close_policy

          unless PARENT_CLOSE_POLICY.key? parent_close_policy
            raise ArgumentError, "Unknown parent_close_policy '#{parent_close_policy}' specified"
          end

          PARENT_CLOSE_POLICY[parent_close_policy]
        end

        def serialize_search_attributes(search_attributes)
          return unless search_attributes

          Temporalio::Api::Common::V1::SearchAttributes.new(indexed_fields: converter.to_payload_map_without_codec(search_attributes))
        end
      end
    end
  end
end
