require 'temporal/workflow/executor'
require 'temporal/workflow/history'
require 'temporal/metadata'
require 'temporal/error_handler'
require 'temporal/errors'

module Temporal
  class Workflow
    class TaskProcessor
      MAX_FAILED_ATTEMPTS = 10

      def initialize(task, namespace, workflow_lookup, client, middleware_chain)
        @task = task
        @namespace = namespace
        @metadata = Metadata.generate(Metadata::WORKFLOW_TASK_TYPE, task, namespace)
        @task_token = task.task_token
        @workflow_name = task.workflow_type.name
        @workflow_class = workflow_lookup.find(workflow_name)
        @client = client
        @middleware_chain = middleware_chain
      end

      def process
        start_time = Time.now

        Temporal.logger.info("Processing a workflow task for #{workflow_name}")
        Temporal.metrics.timing('workflow_task.queue_time', queue_time_ms, workflow: workflow_name)

        if !workflow_class
          raise Temporal::WorkflowNotRegistered, 'Workflow is not registered with this worker'
        end

        history = fetch_full_history
        # TODO: For sticky workflows we need to cache the Executor instance
        executor = Workflow::Executor.new(workflow_class, history)

        commands = middleware_chain.invoke(metadata) do
          executor.run
        end

        complete_task(commands)
      rescue StandardError => error
        fail_task(error)

        Temporal.logger.error("Workflow task for #{workflow_name} failed with: #{error.inspect}")
        Temporal.logger.debug(error.backtrace.join("\n"))

        Temporal::ErrorHandler.handle(error, metadata: metadata)
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing('workflow_task.latency', time_diff_ms, workflow: workflow_name)
        Temporal.logger.debug("Workflow task processed in #{time_diff_ms}ms")
      end

      private

      attr_reader :task, :namespace, :task_token, :workflow_name, :workflow_class, :client, :middleware_chain, :metadata

      def queue_time_ms
        scheduled = task.scheduled_time.to_f
        started = task.started_time.to_f
        ((started - scheduled) * 1_000).round
      end

      def fetch_full_history
        events = task.history.events.to_a
        next_page_token = task.next_page_token

        while !next_page_token.empty? do
          response = client.get_workflow_execution_history(
            namespace: namespace,
            workflow_id: task.workflow_execution.workflow_id,
            run_id: task.workflow_execution.run_id,
            next_page_token: next_page_token
          )

          events += response.history.events.to_a
          next_page_token = response.next_page_token
        end

        Workflow::History.new(events)
      end

      def complete_task(commands)
        Temporal.logger.info("Workflow task for #{workflow_name} completed")

        client.respond_workflow_task_completed(task_token: task_token, commands: commands)
      end

      def fail_task(error)
        Temporal.logger.error("Workflow task for #{workflow_name} failed with: #{error.inspect}")
        Temporal.logger.debug(error.backtrace.join("\n"))

        # Stop from getting into infinite loop if the error persists
        return if task.attempt >= MAX_FAILED_ATTEMPTS

        client.respond_workflow_task_failed(
          task_token: task_token,
          cause: Temporal::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_UNHANDLED_COMMAND,
          exception: error
        )
      rescue StandardError => error
        Temporal.logger.error("Unable to fail Workflow task #{workflow_name}: #{error.inspect}")

        Temporal::ErrorHandler.handle(error, metadata: metadata)
      end
    end
  end
end
