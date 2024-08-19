require "temporal/connection/serializer/base"
require "temporal/connection/serializer/schedule_overlap_policy"

module Temporal
  module Connection
    module Serializer
      class Backfill < Base
        def to_proto
          return unless object

          Temporalio::Api::Schedule::V1::BackfillRequest.new(
            start_time: serialize_time(object.start_time),
            end_time: serialize_time(object.end_time),
            overlap_policy: Temporal::Connection::Serializer::ScheduleOverlapPolicy.new(object.overlap_policy, converter).to_proto
          )
        end

        def serialize_time(input_time)
          return unless input_time

          Google::Protobuf::Timestamp.new.from_time(input_time)
        end
      end
    end
  end
end
