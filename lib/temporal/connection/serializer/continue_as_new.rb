require 'temporal/connection/serializer/base'
require 'temporal/connection/serializer/retry_policy'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class ContinueAsNew < Base
        include Concerns::Payloads

        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_CONTINUE_AS_NEW_WORKFLOW_EXECUTION,
            continue_as_new_workflow_execution_command_attributes:
              Temporalio::Api::Command::V1::ContinueAsNewWorkflowExecutionCommandAttributes.new(
                workflow_type: Temporalio::Api::Common::V1::WorkflowType.new(name: object.workflow_type),
                task_queue: Temporalio::Api::TaskQueue::V1::TaskQueue.new(name: object.task_queue),
                input: to_payloads(object.input),
                workflow_run_timeout: object.timeouts[:run],
                workflow_task_timeout: object.timeouts[:task],
                retry_policy: Temporal::Connection::Serializer::RetryPolicy.new(object.retry_policy).to_proto,
                header: serialize_headers(object.headers),
                memo: serialize_memo(object.memo),
                search_attributes: serialize_search_attributes(object.search_attributes),
              )
          )
        end

        private

        def serialize_headers(headers)
          return unless headers

          Temporalio::Api::Common::V1::Header.new(fields: to_payload_map(headers))
        end

        def serialize_memo(memo)
          return unless memo

          Temporalio::Api::Common::V1::Memo.new(fields: to_payload_map(memo))
        end

        def serialize_search_attributes(search_attributes)
          return unless search_attributes

          Temporalio::Api::Common::V1::SearchAttributes.new(indexed_fields: to_payload_map_without_codec(search_attributes))
        end
      end
    end
  end
end
