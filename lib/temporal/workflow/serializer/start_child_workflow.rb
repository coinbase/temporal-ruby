require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class StartChildWorkflow < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_START_CHILD_WORKFLOW_EXECUTION,
            start_child_workflow_execution_command_attributes:
              Temporal::Api::StartChildWorkflowExecutionCommandAttributes.new(
                namespace: object.namespace,
                workflow_id: object.workflow_id.to_s,
                workflow_type: Temporal::Api::WorkflowType.new(name: object.workflow_type),
                task_queue: Temporal::Api::TaskQueue.new(name: object.task_queue),
                input: Temporal::Api::Common::V1::Payloads.new(
                  payloads: [
                    Temporal::Api::Common::V1::Payload.new(
                      data: JSON.serialize(object.input)
                    )
                  ]
                ),
                execution_start_to_close_timeout: object.timeouts[:execution],
                task_start_to_close_timeout: object.timeouts[:task],
                retry_policy: serialize_retry_policy(object.retry_policy),
                header: serialize_headers(object.headers)
              )
          )
        end

        private

        def serialize_retry_policy(retry_policy)
          return unless retry_policy

          non_retriable_errors = Array(retry_policy.non_retriable_errors).map(&:name)
          options = {
            initial_interval: retry_policy.interval,
            backoff_coefficient: retry_policy.backoff,
            maximum_interval: retry_policy.max_interval,
            maximum_attempts: retry_policy.max_attempts,
            non_retriable_error_reasons: non_retriable_errors,
          }.compact

          Temporal::Api::Common::V1::RetryPolicy.new(options)
        end

        def serialize_headers(headers)
          return unless headers

          Temporal::Api::Common::V1::Header.new(fields: object.headers)
        end
      end
    end
  end
end
