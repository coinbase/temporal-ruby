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

    def initialize(size, rate_limit: nil)
      @size = size
      @limiter = Limiter::RateQueue.new(rate_limit, interval: 1) if rate_limit
      @queue = Queue.new
      @mutex = Mutex.new
      @availability = ConditionVariable.new
      @available_threads = size
      @pool = Array.new(size) do |i|
        Thread.new { poll }
      end
    end

    def wait_for_available_threads
      @mutex.synchronize do
        while @available_threads <= 0
          @availability.wait(@mutex)
        end
      end
    end

    def schedule(&block)
      wait_for_available_rate_limit
      @mutex.synchronize do
        @available_threads -= 1
        @queue << block
      end
    end

    def shutdown
      size.times do
        schedule { throw EXIT_SYMBOL }
      end

      @pool.each(&:join)
    end

    private

    def wait_for_available_rate_limit
      @limiter&.shift
    end

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
        end
      end
    end
  end
end
