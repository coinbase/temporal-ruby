require "temporal/schedule/schedule_spec"
require "temporal/schedule/interval"
require "temporal/schedule/calendar"
require "temporal/connection/serializer/schedule_spec"

describe Temporal::Connection::Serializer::ScheduleSpec do
  let(:example_spec) do
    Temporal::Schedule::ScheduleSpec.new(
      cron_expressions: ["@hourly"],
      intervals: [
        Temporal::Schedule::Interval.new(every: 50, offset: 30),
        Temporal::Schedule::Interval.new(every: 60)
      ],
      calendars: [
        Temporal::Schedule::Calendar.new(
          hour: "7",
          minute: "0,3,15",
          day_of_week: "MONDAY",
          month: "1-6",
          comment: "some comment explaining intent"
        ),
        Temporal::Schedule::Calendar.new(
          minute: "8",
          hour: "*"
        )
      ],
      start_time: Time.new(2000, 1, 1, 0, 0, 0),
      end_time: Time.new(2031, 1, 1, 0, 0, 0),
      jitter: 500,
      timezone_name: "America/New_York"
    )
  end

  describe "to_proto" do
    it "produces well-formed protobuf" do
      result = described_class.new(example_spec).to_proto

      expect(result).to(be_a(Temporalio::Api::Schedule::V1::ScheduleSpec))
      expect(result.cron_string).to(eq(["@hourly"]))
      expect(result.interval[0].interval.seconds).to(eq(50))
      expect(result.interval[0].phase.seconds).to(eq(30))
      expect(result.interval[1].interval.seconds).to(eq(60))
      expect(result.interval[1].phase).to(be_nil)
      expect(result.calendar[0].hour).to(eq("7"))
      expect(result.calendar[0].minute).to(eq("0,3,15"))
      expect(result.calendar[0].day_of_week).to(eq("MONDAY"))
      expect(result.calendar[0].month).to(eq("1-6"))
      expect(result.calendar[0].comment).to(eq("some comment explaining intent"))
      expect(result.calendar[1].hour).to(eq("*"))
      expect(result.calendar[1].minute).to(eq("8"))
      expect(result.start_time.to_time).to(eq(example_spec.start_time))
      expect(result.end_time.to_time).to(eq(example_spec.end_time))
      expect(result.jitter.seconds).to(eq(500))
      expect(result.timezone_name).to(eq("America/New_York"))
    end
  end
end
