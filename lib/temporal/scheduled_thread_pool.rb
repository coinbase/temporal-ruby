require 'temporal/metric_keys'

# This class implements a thread pool for scheduling tasks with a delay.
# If threads are all occupied when a task is scheduled, it will be queued
# with the sleep delay adjusted based on the wait time. 
module Temporal
  class ScheduledThreadPool
    attr_reader :size

    ScheduledItem = Struct.new(:id, :job, :fire_at, :canceled, keyword_init: true)

    def initialize(size, metrics_tags)
      @size = size
      @metrics_tags = metrics_tags
      @queue = Queue.new
      @mutex = Mutex.new
      @available_threads = size
      @occupied_threads = {}
      @pool = Array.new(size) do |_i|
        Thread.new { poll }
      end
    end

    def schedule(id, delay, &block)
      item = ScheduledItem.new(
        id: id,
        job: block,
        fire_at: Time.now + delay,
        canceled: false)
      @mutex.synchronize do
        @available_threads -= 1
        @queue << item
      end

      report_metrics

      item
    end

    def cancel(item)
      thread = @mutex.synchronize do
        @occupied_threads[item.id]
      end

      item.canceled = true
      unless thread.nil?
        thread.raise(CancelError.new)
      end

      item
    end

    def shutdown
      size.times do
        @mutex.synchronize do
          @queue << EXIT_SYMBOL
        end
      end

      @pool.each(&:join)
    end

    private

    class CancelError < StandardError; end
    EXIT_SYMBOL = :exit

    def poll
      loop do
        item = @queue.pop
        if item == EXIT_SYMBOL
          return
        end

        begin
          Thread.handle_interrupt(CancelError => :immediate) do
            @mutex.synchronize do
              @occupied_threads[item.id] = Thread.current
            end

            if !item.canceled
              delay = item.fire_at - Time.now
              if delay > 0
                sleep delay
              end
            end
          end

          # Job call is outside cancel handle interrupt block because the job can't
          # reliably be stopped once running. It's still in the begin/rescue block
          # so that it won't be executed if the thread gets canceled.
          if !item.canceled
            item.job.call
          end
        rescue CancelError
        end

        @mutex.synchronize do
          @available_threads += 1
          @occupied_threads.delete(item.id)
        end

        report_metrics
      end
    end

    def report_metrics
      Temporal.metrics.gauge(Temporal::MetricKeys::THREAD_POOL_AVAILABLE_THREADS, @available_threads, @metrics_tags)
    end
  end
end
