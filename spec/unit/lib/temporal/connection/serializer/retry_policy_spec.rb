require 'temporal/retry_policy'
require 'temporal/connection/serializer/retry_policy'

describe Temporal::Connection::Serializer::RetryPolicy do
  let(:config) { Temporal::Configuration.new }

  describe 'to_proto' do
    let(:example_policy) do
      Temporal::RetryPolicy.new(
        interval: 1,
        backoff: 1.5,
        max_interval: 5,
        max_attempts: 3,
        non_retriable_errors: [StandardError]
      )
    end

    it 'converts to proto' do
      proto = described_class.new(example_policy, config.converter).to_proto
      expect(proto.initial_interval.seconds).to eq(1)
      expect(proto.backoff_coefficient).to eq(1.5)
      expect(proto.maximum_interval.seconds).to eq(5)
      expect(proto.maximum_attempts).to eq(3)
      expect(proto.non_retryable_error_types).to eq(['StandardError'])
    end
  end
end
