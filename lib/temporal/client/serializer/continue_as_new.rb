require 'temporal/client/serializer/base'
require 'temporal/client/serializer/retry_policy'
require 'temporal/concerns/payloads'

module Temporal
  module Client
    module Serializer
      class ContinueAsNew < Base
        include Concerns::Payloads

        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_CONTINUE_AS_NEW_WORKFLOW_EXECUTION,
            continue_as_new_workflow_execution_command_attributes:
              Temporal::Api::Command::V1::ContinueAsNewWorkflowExecutionCommandAttributes.new(
                workflow_type: Temporal::Api::Common::V1::WorkflowType.new(name: object.workflow_type),
                task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(name: object.task_queue),
                input: to_payloads(object.input),
                workflow_run_timeout: object.timeouts[:execution],
                workflow_task_timeout: object.timeouts[:task],
                retry_policy: Temporal::Client::Serializer::RetryPolicy.new(object.retry_policy).to_proto,
                header: serialize_headers(object.headers)
              )
          )
        end

        private

        def serialize_headers(headers)
          return unless headers

          Temporal::Api::Common::V1::Header.new(fields: object.headers)
        end
      end
    end
  end
end
