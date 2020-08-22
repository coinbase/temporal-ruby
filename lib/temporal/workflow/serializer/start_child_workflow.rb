require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class StartChildWorkflow < Base
        def to_proto
          Temporal::Api::Decision.new(
            decisionType: Temporal::Api::DecisionType::StartChildWorkflowExecution,
            startChildWorkflowExecutionDecisionAttributes:
              Temporal::Api::StartChildWorkflowExecutionDecisionAttributes.new(
                namespace: object.domain,
                workflowId: object.workflow_id.to_s,
                workflowType: Temporal::Api::WorkflowType.new(name: object.workflow_type),
                taskList: Temporal::Api::TaskList.new(name: object.task_list),
                input: Temporal::Api::Payloads.new(
                  payloads: [
                    Temporal::Api::Payload.new(
                      data: JSON.serialize(object.input)
                    )
                  ]
                ),
                executionStartToCloseTimeoutSeconds: object.timeouts[:execution],
                taskStartToCloseTimeoutSeconds: object.timeouts[:task],
                retryPolicy: serialize_retry_policy(object.retry_policy),
                header: serialize_headers(object.headers)
              )
          )
        end

        private

        def serialize_retry_policy(retry_policy)
          return unless retry_policy

          non_retriable_errors = Array(retry_policy.non_retriable_errors).map(&:name)
          options = {
            initialIntervalInSeconds: retry_policy.interval,
            backoffCoefficient: retry_policy.backoff,
            maximumIntervalInSeconds: retry_policy.max_interval,
            maximumAttempts: retry_policy.max_attempts,
            nonRetriableErrorReasons: non_retriable_errors,
            expirationIntervalInSeconds: retry_policy.expiration_interval
          }.compact

          Temporal::Api::RetryPolicy.new(options)
        end

        def serialize_headers(headers)
          return unless headers

          Temporal::Api::Header.new(fields: object.headers)
        end
      end
    end
  end
end
