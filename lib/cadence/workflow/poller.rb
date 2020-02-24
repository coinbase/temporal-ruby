require 'cadence/client'
require 'cadence/workflow/decider'

module Cadence
  class Workflow
    class Poller
      def initialize(domain, task_list, workflow_lookup)
        @domain = domain
        @task_list = task_list
        @workflow_lookup = workflow_lookup
        @shutting_down = false
      end

      def start
        @shutting_down = false
        @thread = Thread.new(&method(:poll_loop))
      end

      def stop
        @shutting_down = true
        Thread.new { Cadence.logger.info('Shutting down a workflow poller') }.join
      end

      def wait
        @thread.join
      end

      private

      attr_reader :domain, :task_list, :client, :workflow_lookup

      def client
        @client ||= Cadence::Client.generate
      end

      def decider
        @decider ||= Decider.new(workflow_lookup, client)
      end

      def shutting_down?
        @shutting_down
      end

      def poll_loop
        while !shutting_down? do
          Cadence.logger.debug("Polling for decision tasks (#{domain} / #{task_list})")

          task = poll_for_task
          process(task) if task&.workflowType
        end
      end

      def poll_for_task
        client.poll_for_decision_task(domain: domain, task_list: task_list)
      rescue StandardError => error
        Cadence.logger.error("Unable to poll for a decision task: #{error.inspect}")
        nil
      end

      def process(task)
        start_time = Time.now

        decider.process(task)

        time_diff = (Time.now - start_time) * 1000
        Cadence.logger.info("Decision task processed in #{time_diff}ms")
      end
    end
  end
end
