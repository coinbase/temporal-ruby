require 'temporal/workflow/executor'
require 'temporal/workflow/history'
require 'temporal/metadata'
require 'temporal/error_handler'
require 'temporal/errors'

module Temporal
  class Workflow
    class TaskProcessor
      Query = Struct.new(:query) do
        include Concerns::Payloads

        def query_type
          query.query_type
        end

        def query_args
          from_query_payloads(query.query_args)
        end
      end

      MAX_FAILED_ATTEMPTS = 1

      def initialize(task, namespace, workflow_lookup, middleware_chain, config)
        @task = task
        @namespace = namespace
        @metadata = Metadata.generate_workflow_task_metadata(task, namespace)
        @task_token = task.task_token
        @workflow_name = task.workflow_type.name
        @workflow_class = workflow_lookup.find(workflow_name)
        @middleware_chain = middleware_chain
        @config = config
      end

      def process
        start_time = Time.now

        Temporal.logger.debug("Processing Workflow task", metadata.to_h)
        Temporal.metrics.timing('workflow_task.queue_time', queue_time_ms, workflow: workflow_name, namespace: namespace)

        if !workflow_class
          raise Temporal::WorkflowNotRegistered, 'Workflow is not registered with this worker'
        end

        history = fetch_full_history
        # TODO: For sticky workflows we need to cache the Executor instance
        executor = Workflow::Executor.new(workflow_class, history, metadata, config)

        commands = middleware_chain.invoke(metadata) do
          executor.run
        end

        # Process deprecated style of query task
        if !task.query.nil?
          result = executor.process_query(Query.new(task.query))
          complete_query(result)
        else
          query_results = if task.queries.any?
            task.queries.each_with_object({}) do |(query_id, query), hash|
              begin
                hash[query_id] = executor.process_query(Query.new(query))
              rescue StandardError => error
                hash[query_id] = error
              end
            end
          end
          complete_task(commands, query_results)
        end
      rescue StandardError => error
        Temporal::ErrorHandler.handle(error, config, metadata: metadata)

        if task.query.nil?
          fail_task(error)
        else
          fail_query(error)
        end
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing('workflow_task.latency', time_diff_ms, workflow: workflow_name, namespace: namespace)
        Temporal.logger.debug("Workflow task processed", metadata.to_h.merge(execution_time: time_diff_ms))
      end

      private

      attr_reader :task, :namespace, :task_token, :workflow_name, :workflow_class,
        :middleware_chain, :metadata, :config

      def connection
        @connection ||= Temporal::Connection.generate(config.for_connection)
      end

      def queue_time_ms
        scheduled = task.scheduled_time.to_f
        started = task.started_time.to_f
        ((started - scheduled) * 1_000).round
      end

      def fetch_full_history
        events = task.history.events.to_a
        next_page_token = task.next_page_token

        while !next_page_token.empty? do
          response = connection.get_workflow_execution_history(
            namespace: namespace,
            workflow_id: task.workflow_execution.workflow_id,
            run_id: task.workflow_execution.run_id,
            next_page_token: next_page_token
          )

          if response.history.events.empty?
            raise Temporal::UnexpectedResponse, 'Received empty history page'
          end

          events += response.history.events.to_a
          next_page_token = response.next_page_token
        end

        Workflow::History.new(events)
      end

      def complete_task(commands, query_results)
        Temporal.logger.info("Workflow task completed", metadata.to_h)

        connection.respond_workflow_task_completed(namespace: namespace, task_token: task_token, commands: commands, query_results: query_results)
      end

      def complete_query(result)
        Temporal.logger.info("Workflow Query task completed", metadata.to_h)

        connection.respond_query_task_completed(
          namespace: namespace,
          task_token: task_token,
          query_result: result
        )
      end

      def fail_query(error)
        Temporal.logger.error("Workflow Query task failed", metadata.to_h.merge(error: error.inspect))
        Temporal.logger.debug(error.backtrace.join("\n"))

        connection.respond_query_task_completed(
          namespace: namespace,
          task_token: task_token,
          error_message: error.message || "Encountered an error during query handling"
        )
      rescue StandardError => error
        Temporal.logger.error("Unable to fail Workflow Query task", metadata.to_h.merge(error: error.inspect))

        Temporal::ErrorHandler.handle(error, config, metadata: metadata)
      end

      def fail_task(error)
        Temporal.logger.error("Workflow task failed", metadata.to_h.merge(error: error.inspect))
        Temporal.logger.debug(error.backtrace.join("\n"))

        # Only fail the workflow task on the first attempt. Subsequent failures of the same workflow task
        # should timeout. This is to avoid spinning on the failed workflow task as the service doesn't
        # yet exponentially backoff on retries.
        return if task.attempt > MAX_FAILED_ATTEMPTS

        connection.respond_workflow_task_failed(
          namespace: namespace,
          task_token: task_token,
          cause: Temporal::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE,
          exception: error
        )
      rescue StandardError => error
        Temporal.logger.error("Unable to fail Workflow task", metadata.to_h.merge(error: error.inspect))

        Temporal::ErrorHandler.handle(error, config, metadata: metadata)
      end
    end
  end
end
