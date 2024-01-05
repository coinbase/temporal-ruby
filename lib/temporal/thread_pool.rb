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

    def initialize(size, config, metrics_tags)
      @size = size
      @metrics_tags = metrics_tags
      @queue = Queue.new
      @mutex = Mutex.new
      @config = config
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
      Thread.current.abort_on_exception = true

      catch(EXIT_SYMBOL) do
        loop do
          job = @queue.pop
          begin
            job.call
          rescue StandardError => e
            Temporal.logger.error('Error reached top of thread pool thread', { error: e.inspect })
            Temporal::ErrorHandler.handle(e, @config)
          rescue Exception => ex
            Temporal.logger.error('Exception reached top of thread pool thread', { error: ex.inspect })
            Temporal::ErrorHandler.handle(ex, @config)
            raise
          end
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
