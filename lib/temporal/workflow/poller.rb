require 'temporal/client'
require 'temporal/thread_pool'
require 'temporal/middleware/chain'
require 'temporal/workflow/task_processor'
require 'temporal/error_handler'

module Temporal
  class Workflow
    class Poller
      DEFAULT_OPTIONS = {
        thread_pool_size: 10
      }.freeze

      def initialize(namespace, task_queue, workflow_lookup, middleware = [], options = {})
        @namespace = namespace
        @task_queue = task_queue
        @workflow_lookup = workflow_lookup
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
        Temporal.logger.info('Shutting down a workflow poller')
      end

      def cancel_pending_requests
        client.cancel_polling_request
      end

      def wait
        thread.join
        thread_pool.shutdown
      end

      private

      attr_reader :namespace, :task_queue, :workflow_lookup, :middleware, :options, :thread

      def client
        @client ||= Temporal::Client.generate
      end

      def shutting_down?
        @shutting_down
      end

      def poll_loop
        loop do
          thread_pool.wait_for_available_threads

          return if shutting_down?

          Temporal.logger.debug("Polling Worklow task queue", { namespace: namespace, task_queue: task_queue })

          task = poll_for_task
          next unless task&.workflow_type

          thread_pool.schedule { process(task) }
        end
      end

      def poll_for_task
        client.poll_workflow_task_queue(namespace: namespace, task_queue: task_queue)
      rescue StandardError => error
        Temporal.logger.error("Unable to poll Workflow task queue", { namespace: namespace, task_queue: task_queue, error: error.inspect })
        Temporal::ErrorHandler.handle(error)

        nil
      end

      def process(task)
        middleware_chain = Middleware::Chain.new(middleware)

        TaskProcessor.new(task, namespace, workflow_lookup, client, middleware_chain).process
      end

      def thread_pool
        @thread_pool ||= ThreadPool.new(options[:thread_pool_size])
      end
    end
  end
end
