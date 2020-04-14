require 'cadence/workflow/serializer/base'
require 'cadence/json'

module Cadence
  class Workflow
    module Serializer
      class StartChildWorkflow < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::StartChildWorkflowExecution,
            startChildWorkflowExecutionDecisionAttributes:
              CadenceThrift::StartChildWorkflowExecutionDecisionAttributes.new(
                domain: object.domain,
                workflowId: object.workflow_id.to_s,
                workflowType: CadenceThrift::WorkflowType.new(name: object.workflow_type),
                taskList: CadenceThrift::TaskList.new(name: object.task_list),
                input: JSON.serialize(object.input),
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

          CadenceThrift::RetryPolicy.new(options)
        end

        def serialize_headers(headers)
          return unless headers

          CadenceThrift::Header.new(fields: object.headers)
        end
      end
    end
  end
end
