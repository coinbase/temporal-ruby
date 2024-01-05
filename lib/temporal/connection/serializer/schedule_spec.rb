require "temporal/connection/serializer/base"

module Temporal
  module Connection
    module Serializer
      class ScheduleSpec < Base
        def to_proto
          return unless object

          Temporalio::Api::Schedule::V1::ScheduleSpec.new(
            cron_string: object.cron_expressions,
            interval: object.intervals.map do |interval|
              Temporalio::Api::Schedule::V1::IntervalSpec.new(
                interval: interval.every,
                phase: interval.offset
              )
            end,
            calendar: object.calendars.map do |calendar|
              Temporalio::Api::Schedule::V1::CalendarSpec.new(
                second: calendar.second,
                minute: calendar.minute,
                hour: calendar.hour,
                day_of_month: calendar.day_of_month,
                month: calendar.month,
                year: calendar.year,
                day_of_week: calendar.day_of_week,
                comment: calendar.comment
              )
            end,
            jitter: object.jitter,
            timezone_name: object.timezone_name,
            start_time: serialize_time(object.start_time),
            end_time: serialize_time(object.end_time)
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
