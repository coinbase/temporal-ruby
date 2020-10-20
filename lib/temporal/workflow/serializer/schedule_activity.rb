require 'temporal/workflow/serializer/base'
require 'temporal/json'

module Temporal
  class Workflow
    module Serializer
      class ScheduleActivity < Base
        def to_proto
          Temporal::Api::Decision::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_SCHEDULE_ACTIVITY_TASK,
            schedule_activity_task_command_attributes:
              Temporal::Api::Decision::V1::ScheduleActivityTaskCommandAttributes.new(
                activity_id: object.activity_id.to_s,
                activity_type: Temporal::Api::Common::V1::ActivityType.new(name: object.activity_type),
                input: Temporal::Api::Common::V1::Payloads.new(
                  payloads: [
                    Temporal::Api::Common::V1::Payload.new(
                      data: JSON.serialize(object.input)
                    )
                  ]
                ),
                namespace: object.domain,
                task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(name: object.task_list),
                schedule_to_close_timeout: object.timeouts[:schedule_to_close],
                schedule_to_start_timeout: object.timeouts[:schedule_to_start],
                start_to_close_timeout: object.timeouts[:start_to_close],
                heartbeat_timeout: object.timeouts[:heartbeat],
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
            expiration_interval: retry_policy.expiration_interval
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
