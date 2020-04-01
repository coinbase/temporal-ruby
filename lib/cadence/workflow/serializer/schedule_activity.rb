require 'cadence/workflow/serializer/base'
require 'cadence/json'

module Cadence
  class Workflow
    module Serializer
      class ScheduleActivity < Base
        def to_thrift
          CadenceThrift::Decision.new(
            decisionType: CadenceThrift::DecisionType::ScheduleActivityTask,
            scheduleActivityTaskDecisionAttributes:
              CadenceThrift::ScheduleActivityTaskDecisionAttributes.new(
                activityId: object.activity_id.to_s,
                activityType: CadenceThrift::ActivityType.new(name: object.activity_type),
                input: JSON.serialize(object.input),
                domain: object.domain,
                taskList: CadenceThrift::TaskList.new(name: object.task_list),
                scheduleToCloseTimeoutSeconds: object.timeouts[:schedule_to_close],
                scheduleToStartTimeoutSeconds: object.timeouts[:schedule_to_start],
                startToCloseTimeoutSeconds: object.timeouts[:start_to_close],
                heartbeatTimeoutSeconds: object.timeouts[:heartbeat],
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
