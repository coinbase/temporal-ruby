require 'temporal/scheduled_thread_pool'

describe Temporal::ScheduledThreadPool do
  before do
    allow(Temporal.metrics).to receive(:gauge)
  end

  let(:size) { 2 }
  let(:tags) { { foo: 'bar', bat: 'baz' } }
  let(:thread_pool) { described_class.new(size, tags) }

  describe '#schedule' do
    it 'executes one task with zero delay on a thread and exits' do
      times = 0

      thread_pool.schedule(:foo, 0) do
        times += 1
      end

      thread_pool.shutdown

      expect(times).to eq(1)
    end

    it 'executes tasks with delays in time order' do
      answers = Queue.new

      thread_pool.schedule(:second, 0.2) do
        answers << :second
      end

      thread_pool.schedule(:first, 0.1) do
        answers << :first
      end

      thread_pool.shutdown

      expect(answers.size).to eq(2)
      expect(answers.pop).to eq(:first)
      expect(answers.pop).to eq(:second)
    end
  end

  describe '#cancel' do
    it 'cancels already waiting task' do
      answers = Queue.new
      handles = []

      handles << thread_pool.schedule(:foo, 30) do
        answers << :foo
      end

      handles << thread_pool.schedule(:bar, 30) do
        answers << :bar
      end

      # Even though this has no wait, it will be blocked by the above
      # two long running tasks until one is finished or cancels.
      handles << thread_pool.schedule(:baz, 0) do
        answers << :baz
      end

      # Canceling one waiting item (foo) will let a blocked one (baz) through
      thread_pool.cancel(handles[0])

      # Canceling the other waiting item (bar) will prevent it from blocking
      # on shutdown
      thread_pool.cancel(handles[1])

      thread_pool.shutdown

      expect(answers.size).to eq(1)
      expect(answers.pop).to eq(:baz)
    end

    it 'cancels blocked task' do
      times = 0
      handles = []

      handles << thread_pool.schedule(:foo, 30) do
        times += 1
      end

      handles << thread_pool.schedule(:bar, 30) do
        times += 1
      end

      # Even though this has no wait, it will be blocked by the above
      # two long running tasks. This test ensures it can be canceled
      # even while waiting to run.
      handles << thread_pool.schedule(:baz, 0) do
        times += 1
      end

      # Cancel this one before it can start running
      thread_pool.cancel(handles[0])

      # Cancel the others so that they don't block shutdown
      thread_pool.cancel(handles[1])
      thread_pool.cancel(handles[2])

      thread_pool.shutdown

      expect(times).to eq(0)
    end
  end

  describe '#new' do
    it 'reports thread available metrics' do
      thread_pool.schedule(:foo, 0) do
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
