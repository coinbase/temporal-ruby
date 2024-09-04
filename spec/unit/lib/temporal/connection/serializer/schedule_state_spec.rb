require "temporal/schedule/schedule_state"
require "temporal/connection/serializer/schedule_state"

describe Temporal::Connection::Serializer::ScheduleState do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end
  let(:example_state) do
    Temporal::Schedule::ScheduleState.new(
      notes: "some notes",
      paused: true,
      limited_actions: true,
      remaining_actions: 500
    )
  end

  describe "to_proto" do
    it "produces well-formed protobuf" do
      result = described_class.new(example_state, converter).to_proto

      expect(result).to(be_a(Temporalio::Api::Schedule::V1::ScheduleState))
      expect(result.notes).to(eq("some notes"))
      expect(result.paused).to(eq(true))
      expect(result.limited_actions).to(eq(true))
      expect(result.remaining_actions).to(eq(500))
    end
  end
end
