require 'temporal/connection/retryer'
require 'temporal/metadata'
require 'time'

describe Temporal::Connection::Retryer do
  before do
    # Skip sleeps during retries to speed up the test.
    allow(Temporal::Connection::Retryer).to receive(:sleep).and_return(nil)
  end

  it 'backs off and stops retrying eventually' do
    sleep_amounts = []
    expect(described_class).to receive(:sleep).exactly(10).times do |amount|
      sleep_amounts << amount
    end

    expect do
      described_class.with_retries(times: 10) do
        raise 'try again'
      end
    end.to raise_error(StandardError)

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
    expect do
      described_class.with_retries do
        raise 'try again'
      end
    end.to raise_error(StandardError)
  end

  it 'can succeed' do
    result = described_class.with_retries do
      5
    end
    expect(result).to eq(5)
  end

  it 'can succeed after retries' do
    i = 0
    result = described_class.with_retries do
      if i < 2
        i += 1
        raise "keep trying"
      else
        6
      end
    end
    expect(result).to eq(6)
  end

  it 'executes the on_retry callback' do
    i = 0
    on_retry_calls = 0
    retries = 2
    on_retry = Proc.new {
      on_retry_calls += 1
    }
    result = described_class.with_retries(on_retry: on_retry) do
      if i < retries
        i += 1
        raise "keep trying"
      else
        6
      end
    end
    expect(on_retry_calls).to equal(retries)
  end

  {
    GRPC::AlreadyExists => false,
    GRPC::Cancelled => false,
    GRPC::FailedPrecondition => false,
    GRPC::InvalidArgument => false,
    GRPC::NotFound => false,
    GRPC::PermissionDenied => false,
    GRPC::Unauthenticated => false,
    GRPC::Unimplemented => false,
    StandardError => true,
    GRPC::Unknown => true,
    GRPC::Unavailable => true
  }.each do |error_class, expect_retry|
    it "#{expect_retry ? 'does' : 'does not'} retry #{error_class}" do
      on_retry_calls = 0
      retried = false
      on_retry = Proc.new {
        on_retry_calls += 1
      }

      begin
        described_class.with_retries(on_retry: on_retry) do
          if !retried
            retried = true
            raise error_class.new("nope")
          end
        end
      rescue => e
        expect(e.class).to eq(error_class)
      ensure
        expect(on_retry_calls).to equal(expect_retry ? 1 : 0)
      end
    end
  end
end

