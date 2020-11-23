require 'temporal/client'
require 'temporal/thread_pool'
require 'temporal/middleware/chain'
require 'temporal/activity/task_processor'

module Temporal
  class Activity
    class Poller
      THREAD_POOL_SIZE = 20

      def initialize(namespace, task_queue, activity_lookup, middleware = [])
        @namespace = namespace
        @task_queue = task_queue
        @activity_lookup = activity_lookup
        @middleware = middleware
        @shutting_down = false
      end

      def start
        @shutting_down = false
        @thread = Thread.new(&method(:poll_loop))
      end

      def stop
        @shutting_down = true
        Temporal.logger.info('Shutting down activity poller')
      end

      def wait
        thread.join
        thread_pool.shutdown
      end

      private

      attr_reader :namespace, :task_queue, :activity_lookup, :middleware, :thread

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

          Temporal.logger.debug("Polling activity task queue (#{namespace} / #{task_queue})")

          task = poll_for_task
          next unless task&.activity_type

          thread_pool.schedule { process(task) }
        end
      end

      def poll_for_task
        client.poll_activity_task_queue(namespace: namespace, task_queue: task_queue)
      rescue StandardError => error
        Temporal.logger.error("Unable to poll activity task queue: #{error.inspect}")
        nil
      end

      def process(task)
        client = Temporal::Client.generate
        middleware_chain = Middleware::Chain.new(middleware)

        TaskProcessor.new(task, namespace, activity_lookup, client, middleware_chain).process
      end

      def thread_pool
        @thread_pool ||= ThreadPool.new(THREAD_POOL_SIZE)
      end
    end
  end
end
