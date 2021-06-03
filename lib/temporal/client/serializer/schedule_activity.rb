require 'temporal/client/serializer/base'
require 'temporal/client/serializer/retry_policy'
require 'temporal/concerns/payloads'

module Temporal
  module Client
    module Serializer
      class ScheduleActivity < Base
        include Concerns::Payloads

        def to_proto
          Temporal::Api::Command::V1::Command.new(
            command_type: Temporal::Api::Enums::V1::CommandType::COMMAND_TYPE_SCHEDULE_ACTIVITY_TASK,
            schedule_activity_task_command_attributes:
              Temporal::Api::Command::V1::ScheduleActivityTaskCommandAttributes.new(
                activity_id: object.activity_id.to_s,
                activity_type: Temporal::Api::Common::V1::ActivityType.new(name: object.activity_type),
                input: to_payloads(object.input),
                namespace: object.namespace,
                task_queue: Temporal::Api::TaskQueue::V1::TaskQueue.new(name: object.task_queue),
                schedule_to_close_timeout: object.timeouts[:schedule_to_close],
                schedule_to_start_timeout: object.timeouts[:schedule_to_start],
                start_to_close_timeout: object.timeouts[:start_to_close],
                heartbeat_timeout: object.timeouts[:heartbeat],
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
