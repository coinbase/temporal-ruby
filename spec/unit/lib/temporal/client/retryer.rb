require 'temporal/client/retryer'
require 'temporal/metadata'
require 'time'

describe Temporal::Client::Retryer do
  it 'backs off and stops retrying eventually' do
    timestamps = []
    max_wait = 2.0
    expect do
      result = described_class.retry_for(max_wait, retry_message: "Still trying", metadata_hash: {}) do
        timestamps << Time.now.to_f
        raise 'try again'
      end
    end.to raise_error(StandardError)
    epsilon = 0.1 # fudge factor for execution time, which isn't tracked in Retryer.
    expect(timestamps.last - timestamps.first).to be <= max_wait + epsilon

    # Test backoff
    initial_interval = 0.2
    backoff = 1.2
    (0..timestamps.length - 2).each do |i|
      expect(timestamps[i + 1] - timestamps[i]).to be >= initial_interval * (backoff**i)
    end
  end

  it 'caps out amount slept' do
    expect(described_class).to receive(:sleep).at_least(10).times do |amount|
      expect(amount).to be <= 6.0 # At most 6 seconds between retries.
    end
    max_wait = 30
    expect do
      described_class.retry_for(max_wait, retry_message: "Still trying", metadata_hash: {}) do
        raise 'try again'
      end
    end.to raise_error(StandardError)
  end

  it 'can succeed' do
    result = described_class.retry_for(1, retry_message: "Still trying", metadata_hash: {}) do
      5
    end
    expect(result).to eq(5)
  end

  it 'can succeed after retries' do
    i = 0
    result = described_class.retry_for(1, retry_message: "Still trying", metadata_hash: {}) do
      if i < 2
        i += 1
        raise "keep trying"
      else
        6
      end
    end
    expect(result).to eq(6)
  end
end

