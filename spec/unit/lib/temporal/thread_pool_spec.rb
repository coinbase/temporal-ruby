require 'temporal/thread_pool'

describe Temporal::ThreadPool do
  before do
    allow(Temporal.metrics).to receive(:gauge)
  end

  let(:config) { Temporal::Configuration.new }
  let(:size) { 2 }
  let(:tags) { { foo: 'bar', bat: 'baz' } }
  let(:thread_pool) { described_class.new(size, config, tags) }

  describe '#new' do
    it 'executes one task on a thread and exits' do
      times = 0

      thread_pool.schedule do
        times += 1
      end

      thread_pool.shutdown

      expect(times).to eq(1)
    end

    it 'handles error without exiting' do
      times = 0

      thread_pool.schedule do
        times += 1
        raise 'failure'
      end

      thread_pool.shutdown

      expect(times).to eq(1)
    end

    it 'handles exception with exiting' do
      Thread.report_on_exception = false
      times = 0

      thread_pool.schedule do
        times += 1
        raise Exception, 'crash'
      end

      begin
        thread_pool.shutdown
      rescue Exception => e
        'ok'
      end

      expect(times).to eq(1)
    end

    it 'reports thread available metrics' do
      thread_pool.schedule do
      end

      thread_pool.shutdown

      # Thread behavior is not deterministic. Ensure the calls match without
      # verifying exact gauge values.
      expect(Temporal.metrics)
        .to have_received(:gauge)
        .with(
          Temporal::MetricKeys::THREAD_POOL_AVAILABLE_THREADS,
          instance_of(Integer),
          tags
        )
        .at_least(:once)
    end
  end
end
