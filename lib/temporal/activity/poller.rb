require 'temporal/client'
require 'temporal/thread_pool'
require 'temporal/middleware/chain'
require 'temporal/activity/task_processor'

module Temporal
  class Activity
    class Poller
      THREAD_POOL_SIZE = 20

      def initialize(namespace, task_list, activity_lookup, middleware = [])
        @namespace = namespace
        @task_list = task_list
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
        Thread.new { Temporal.logger.info('Shutting down activity poller') }.join
      end

      def wait
        thread.join
      end

      private

      attr_reader :namespace, :task_list, :activity_lookup, :middleware, :thread

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

          Temporal.logger.debug("Polling for activity tasks (#{namespace} / #{task_list})")

          task = poll_for_task
          next if task.activity_id.empty?

          thread_pool.schedule { process(task) }
        end
      end

      def poll_for_task
        client.poll_for_activity_task(namespace: namespace, task_list: task_list)
      rescue StandardError => error
        Temporal.logger.error("Unable to poll for an activity task: #{error.inspect}")
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
