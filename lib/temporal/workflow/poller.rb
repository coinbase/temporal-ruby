require 'temporal/client'
require 'temporal/middleware/chain'
require 'temporal/workflow/task_processor'

module Temporal
  class Workflow
    class Poller
      def initialize(namespace, task_queue, workflow_lookup, middleware = [])
        @namespace = namespace
        @task_queue = task_queue
        @workflow_lookup = workflow_lookup
        @middleware = middleware
        @shutting_down = false
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
        @thread.join
      end

      private

      attr_reader :namespace, :task_queue, :client, :workflow_lookup, :middleware

      def client
        @client ||= Temporal::Client.generate
      end

      def middleware_chain
        @middleware_chain ||= Middleware::Chain.new(middleware)
      end

      def shutting_down?
        @shutting_down
      end

      def poll_loop
        while !shutting_down? do
          Temporal.logger.debug("Polling worklow task queue (#{namespace} / #{task_queue})")

          task = poll_for_task
          process(task) if task&.workflow_type
        end
      end

      def poll_for_task
        client.poll_workflow_task_queue(namespace: namespace, task_queue: task_queue)
      rescue StandardError => error
        Temporal.logger.error("Unable to poll workflow task queue: #{error.inspect}")

        Temporal::ErrorHandler.handle(error)

        nil
      end

      def process(task)
        TaskProcessor.new(task, namespace, workflow_lookup, client, middleware_chain).process
      end
    end
  end
end
