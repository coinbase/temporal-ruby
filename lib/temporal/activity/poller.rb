require 'temporal/connection'
require 'temporal/thread_pool'
require 'temporal/middleware/chain'
require 'temporal/activity/task_processor'
require 'temporal/error_handler'

module Temporal
  class Activity
    class Poller
      DEFAULT_OPTIONS = {
        thread_pool_size: 20
      }.freeze

      def initialize(namespace, task_queue, activity_lookup, config, middleware = [], options = {})
        @namespace = namespace
        @task_queue = task_queue
        @activity_lookup = activity_lookup
        @config = config
        @middleware = middleware
        @shutting_down = false
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def start
        @shutting_down = false
        @thread = Thread.new(&method(:poll_loop))
      end

      def stop_polling
        @shutting_down = true
        Temporal.logger.info('Shutting down activity poller', { namespace: namespace, task_queue: task_queue })
      end

      def cancel_pending_requests
        connection.cancel_polling_request
      end

      def wait
        thread.join
        thread_pool.shutdown
      end

      private

      attr_reader :namespace, :task_queue, :activity_lookup, :config, :middleware, :options, :thread
      
      def connection
        @connection ||= Temporal::Connection.generate(config.for_connection, options)
      end

      def shutting_down?
        @shutting_down
      end

      def poll_loop
        last_poll_time = Time.now
        metrics_tags = { namespace: namespace, task_queue: task_queue }.freeze

        loop do
          thread_pool.wait_for_available_threads

          return if shutting_down?

          time_diff_ms = ((Time.now - last_poll_time) * 1000).round
          Temporal.metrics.timing('activity_poller.time_since_last_poll', time_diff_ms, metrics_tags)
          Temporal.logger.debug("Polling activity task queue", { namespace: namespace, task_queue: task_queue })

          task = poll_for_task
          last_poll_time = Time.now
          next unless task&.activity_type

          thread_pool.schedule { process(task) }
        end
      end

      def poll_for_task
        connection.poll_activity_task_queue(namespace: namespace, task_queue: task_queue)
      rescue StandardError => error
        Temporal.logger.error("Unable to poll activity task queue", { namespace: namespace, task_queue: task_queue, error: error.inspect })

        Temporal::ErrorHandler.handle(error)

        nil
      end

      def process(task)
        middleware_chain = Middleware::Chain.new(middleware)

        TaskProcessor.new(task, namespace, activity_lookup, middleware_chain, config).process
      end

      def thread_pool
        @thread_pool ||= ThreadPool.new(options[:thread_pool_size])
      end
    end
  end
end
