require "temporal/connection/serializer/base"
require "temporal/connection/serializer/schedule_overlap_policy"

module Temporal
  module Connection
    module Serializer
      class SchedulePolicies < Base
        def to_proto
          return unless object

          Temporalio::Api::Schedule::V1::SchedulePolicies.new(
            overlap_policy: Temporal::Connection::Serializer::ScheduleOverlapPolicy.new(object.overlap_policy).to_proto,
            catchup_window: object.catchup_window,
            pause_on_failure: object.pause_on_failure
          )
        end
      end
    end
  end
end
