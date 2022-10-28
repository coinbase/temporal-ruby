require 'temporal/metric_keys'

# This class implements a very simple ThreadPool with the ability to
# block until at least one thread becomes available. This allows Pollers
# to only poll when there's an available thread in the pool.
#
# NOTE: There's a minor race condition that can occur between calling
#       #wait_for_available_threads and #schedule, but should be rare
#
module Temporal
  class ThreadPool
    attr_reader :size

    def initialize(size, metrics_tags)
      @size = size
      @metrics_tags = metrics_tags
      @queue = Queue.new
      @mutex = Mutex.new
      @availability = ConditionVariable.new
      @available_threads = size
      @pool = Array.new(size) do |_i|
        Thread.new { poll }
      end
    end

    def report_metrics
      Temporal.metrics.gauge(Temporal::MetricKeys::THREAD_POOL_AVAILABLE_THREADS, @available_threads, @metrics_tags)
    end

    def wait_for_available_threads
      @mutex.synchronize do
        @availability.wait(@mutex) while @available_threads <= 0
      end
    end

    def schedule(&block)
      @mutex.synchronize do
        @available_threads -= 1
        @queue << block
      end

      report_metrics
    end

    def shutdown
      size.times do
        schedule { throw EXIT_SYMBOL }
      end

      @pool.each(&:join)
    end

    private

    EXIT_SYMBOL = :exit

    def poll
      catch(EXIT_SYMBOL) do
        loop do
          job = @queue.pop
          job.call
          @mutex.synchronize do
            @available_threads += 1
            @availability.signal
          end

          report_metrics
        end
      end
    end
  end
end
