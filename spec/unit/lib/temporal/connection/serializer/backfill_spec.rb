require "temporal/connection/errors"
require "temporal/schedule/backfill"
require "temporal/connection/serializer/backfill"

describe Temporal::Connection::Serializer::Backfill do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end
  let(:example_backfill) do
    Temporal::Schedule::Backfill.new(
      start_time: Time.new(2000, 1, 1, 0, 0, 0),
      end_time: Time.new(2031, 1, 1, 0, 0, 0),
      overlap_policy: :buffer_all
    )
  end

  describe "to_proto" do
    it "raises an error if an invalid overlap_policy is specified" do
      invalid = Temporal::Schedule::Backfill.new(overlap_policy: :foobar)
      expect do
        described_class.new(invalid, converter).to_proto
      end
        .to(raise_error(Temporal::Connection::ArgumentError, "Unknown schedule overlap policy specified: foobar"))
    end

    it "produces well-formed protobuf" do
      result = described_class.new(example_backfill, converter).to_proto

      expect(result).to(be_a(Temporalio::Api::Schedule::V1::BackfillRequest))
      expect(result.overlap_policy).to(eq(:SCHEDULE_OVERLAP_POLICY_BUFFER_ALL))
      expect(result.start_time.to_time).to(eq(example_backfill.start_time))
      expect(result.end_time.to_time).to(eq(example_backfill.end_time))
    end
  end
end
