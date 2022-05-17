require 'grpc/errors'
require 'temporal/connection'
require 'temporal/thread_pool'
require 'temporal/middleware/chain'
require 'temporal/workflow/task_processor'
require 'temporal/error_handler'

module Temporal
  class Workflow
    class Poller
      DEFAULT_OPTIONS = {
        thread_pool_size: 10,
        binary_checksum: nil
      }.freeze

      def initialize(namespace, task_queue, workflow_lookup, config, middleware = [], options = {})
        @namespace = namespace
        @task_queue = task_queue
        @workflow_lookup = workflow_lookup
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
        Temporal.logger.info('Shutting down a workflow poller', { namespace: namespace, task_queue: task_queue })
      end

      def cancel_pending_requests
        connection.cancel_polling_request
      end

      def wait
        if !shutting_down?
          raise "Workflow poller waiting for shutdown completion without being in shutting_down state!"
        end
        thread.join
        thread_pool.shutdown
      end

      private

      attr_reader :namespace, :task_queue, :connection, :workflow_lookup, :config, :middleware, :options, :thread

      def connection
        @connection ||= Temporal::Connection.generate(config.for_connection)
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
          Temporal.metrics.timing('workflow_poller.time_since_last_poll', time_diff_ms, metrics_tags)
          Temporal.logger.debug("Polling workflow task queue", { namespace: namespace, task_queue: task_queue })

          task = poll_for_task
          last_poll_time = Time.now
          next unless task&.workflow_type

          thread_pool.schedule { process(task) }
        end
      end

      def poll_for_task
        connection.poll_workflow_task_queue(namespace: namespace, task_queue: task_queue, binary_checksum: binary_checksum)
      rescue ::GRPC::Cancelled
        # We're shutting down and we've already reported that in the logs
        nil
      rescue StandardError => error
        Temporal.logger.error("Unable to poll Workflow task queue", { namespace: namespace, task_queue: task_queue, error: error.inspect })
        Temporal::ErrorHandler.handle(error, config)

        nil
      end

      def process(task)
        middleware_chain = Middleware::Chain.new(middleware)

        TaskProcessor.new(task, namespace, workflow_lookup, middleware_chain, config, binary_checksum).process
      end

      def thread_pool
        @thread_pool ||= ThreadPool.new(options[:thread_pool_size])
      end

      def binary_checksum
        options[:binary_checksum]
      end
    end
  end
end
