require "temporal/connection/serializer/base"

module Temporal
  module Connection
    module Serializer
      class ScheduleOverlapPolicy < Base
        SCHEDULE_OVERLAP_POLICY = {
          skip: Temporalio::Api::Enums::V1::ScheduleOverlapPolicy::SCHEDULE_OVERLAP_POLICY_SKIP,
          buffer_one: Temporalio::Api::Enums::V1::ScheduleOverlapPolicy::SCHEDULE_OVERLAP_POLICY_BUFFER_ONE,
          buffer_all: Temporalio::Api::Enums::V1::ScheduleOverlapPolicy::SCHEDULE_OVERLAP_POLICY_BUFFER_ALL,
          cancel_other: Temporalio::Api::Enums::V1::ScheduleOverlapPolicy::SCHEDULE_OVERLAP_POLICY_CANCEL_OTHER,
          terminate_other: Temporalio::Api::Enums::V1::ScheduleOverlapPolicy::SCHEDULE_OVERLAP_POLICY_TERMINATE_OTHER,
          allow_all: Temporalio::Api::Enums::V1::ScheduleOverlapPolicy::SCHEDULE_OVERLAP_POLICY_ALLOW_ALL
        }.freeze

        def to_proto
          return unless object

          SCHEDULE_OVERLAP_POLICY.fetch(object) do
            raise ArgumentError, "Unknown schedule overlap policy specified: #{object}"
          end
        end
      end
    end
  end
end
