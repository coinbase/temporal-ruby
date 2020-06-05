require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class ScheduleActivity < Base
        def to_thrift
          TemporalThrift::Decision.new(
            decisionType: TemporalThrift::DecisionType::ScheduleActivityTask,
            scheduleActivityTaskDecisionAttributes:
              TemporalThrift::ScheduleActivityTaskDecisionAttributes.new(
                activityId: object.activity_id.to_s,
                activityType: TemporalThrift::ActivityType.new(name: object.activity_type),
                input: JSON.serialize(object.input),
                domain: object.domain,
                taskList: TemporalThrift::TaskList.new(name: object.task_list),
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

          TemporalThrift::RetryPolicy.new(options)
        end

        def serialize_headers(headers)
          return unless headers

          TemporalThrift::Header.new(fields: object.headers)
        end
      end
    end
  end
end
