require 'temporal/client/retryer'
require 'temporal/metadata'
require 'time'

describe Temporal::Client::Retryer do
  it 'backs off and stops retrying eventually' do
    sleep_amounts = []
    max_wait = 6.0
    expect(described_class).to receive(:sleep).at_least(10).times do |amount|
      sleep_amounts << amount
    end

    expect do
      result = described_class.retry_for(max_wait, retry_message: "Still trying", metadata_hash: {}) do
        raise 'try again'
      end
    end.to raise_error(StandardError)
    expect(sleep_amounts.sum).to be <= max_wait

    # Test backoff
    initial_interval = 0.2
    backoff = 1.2

    sleep_amounts.each_with_index do |sleep_amount, i|
      expect(sleep_amount).to be_within(0.01).of(initial_interval * (backoff**i))
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

