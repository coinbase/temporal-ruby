require "temporal/schedule/schedule_policies"
require "temporal/connection/serializer/schedule_policies"

describe Temporal::Connection::Serializer::SchedulePolicies do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end
  let(:example_policies) do
    Temporal::Schedule::SchedulePolicies.new(
      overlap_policy: :buffer_one,
      catchup_window: 600,
      pause_on_failure: true
    )
  end

  describe "to_proto" do
    it "produces well-formed protobuf" do
      result = described_class.new(example_policies, converter).to_proto

      expect(result).to(be_a(Temporalio::Api::Schedule::V1::SchedulePolicies))
      expect(result.overlap_policy).to(eq(:SCHEDULE_OVERLAP_POLICY_BUFFER_ONE))
      expect(result.catchup_window.seconds).to(eq(600))
      expect(result.pause_on_failure).to(eq(true))
    end

    it "should raise if an unknown overlap policy is specified" do
      invalid_policies = Temporal::Schedule::SchedulePolicies.new(overlap_policy: :foobar)
      expect do
        described_class.new(invalid_policies, converter).to_proto
      end
        .to(raise_error(Temporal::Connection::ArgumentError, "Unknown schedule overlap policy specified: foobar"))
    end
  end
end
