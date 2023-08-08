require 'temporal/error_handler'
require 'temporal/errors'
require 'temporal/metadata'
require 'temporal/workflow/executor'
require 'temporal/workflow/history'
require 'temporal/workflow/stack_trace_tracker'
require 'temporal/metric_keys'

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
      LEGACY_QUERY_KEY = :legacy_query

      def initialize(task, namespace, workflow_lookup, middleware_chain, workflow_middleware_chain, config, binary_checksum)
        @task = task
        @namespace = namespace
        @metadata = Metadata.generate_workflow_task_metadata(task, namespace)
        @task_token = task.task_token
        @workflow_name = task.workflow_type.name
        @workflow_class = workflow_lookup.find(workflow_name)
        @middleware_chain = middleware_chain
        @workflow_middleware_chain = workflow_middleware_chain
        @config = config
        @binary_checksum = binary_checksum
      end

      def process
        start_time = Time.now

        Temporal.logger.debug('Processing Workflow task', metadata.to_h)
        Temporal.metrics.timing(Temporal::MetricKeys::WORKFLOW_TASK_QUEUE_TIME, queue_time_ms, workflow: workflow_name,
                                                                                               namespace: namespace)

        raise Temporal::WorkflowNotRegistered, 'Workflow is not registered with this worker' unless workflow_class

        history = fetch_full_history
        queries = parse_queries

        # We only need to track the stack trace if this is a stack trace query
        track_stack_trace = queries.values.map(&:query_type).include?(StackTraceTracker::STACK_TRACE_QUERY_NAME)

        # TODO: For sticky workflows we need to cache the Executor instance
        executor = Workflow::Executor.new(workflow_class, history, metadata, config, track_stack_trace,
                                          workflow_middleware_chain)

        run_result = middleware_chain.invoke(metadata) do
          executor.run
        end

        query_results = executor.process_queries(queries)

        if legacy_query_task?
          complete_query(query_results[LEGACY_QUERY_KEY])
        else
          complete_task(run_result, query_results)
        end
      rescue StandardError => e
        Temporal::ErrorHandler.handle(e, config, metadata: metadata)

        fail_task(e)
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing(Temporal::MetricKeys::WORKFLOW_TASK_LATENCY, time_diff_ms, workflow: workflow_name,
                                                                                           namespace: namespace)
        Temporal.logger.debug('Workflow task processed', metadata.to_h.merge(execution_time: time_diff_ms))
      end

      private

      attr_reader :task, :namespace, :task_token, :workflow_name, :workflow_class,
                  :middleware_chain, :workflow_middleware_chain, :metadata, :config, :binary_checksum

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
        until next_page_token.empty?
          response = connection.get_workflow_execution_history(
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

      def legacy_query_task?
        !!task.query
      end

      def parse_queries
        # Support for deprecated query style
        if legacy_query_task?
          { LEGACY_QUERY_KEY => Query.new(task.query) }
        else
          task.queries.each_with_object({}) do |(query_id, query), result|
            result[query_id] = Query.new(query)
          end
        end
      end

      def complete_task(run_result, query_results)
        Temporal.logger.info('Workflow task completed', metadata.to_h)

        connection.respond_workflow_task_completed(
          namespace: namespace,
          task_token: task_token,
          commands: run_result.commands,
          binary_checksum: binary_checksum,
          query_results: query_results,
          new_sdk_flags_used: run_result.new_sdk_flags_used
        )
      end

      def complete_query(result)
        Temporal.logger.info('Workflow Query task completed', metadata.to_h)

        connection.respond_query_task_completed(
          namespace: namespace,
          task_token: task_token,
          query_result: result
        )
      rescue StandardError => e
        Temporal.logger.error('Unable to complete a query', metadata.to_h.merge(error: e.inspect))

        Temporal::ErrorHandler.handle(e, config, metadata: metadata)
      end

      def fail_task(error)
        Temporal.metrics.increment(Temporal::MetricKeys::WORKFLOW_TASK_EXECUTION_FAILED, workflow: workflow_name,
                                                                                         namespace: namespace)
        Temporal.logger.error('Workflow task failed', metadata.to_h.merge(error: error.inspect))
        Temporal.logger.debug(error.backtrace.join("\n"))

        # Only fail the workflow task on the first attempt. Subsequent failures of the same workflow task
        # should timeout. This is to avoid spinning on the failed workflow task as the service doesn't
        # yet exponentially backoff on retries.
        return if task.attempt > MAX_FAILED_ATTEMPTS

        connection.respond_workflow_task_failed(
          namespace: namespace,
          task_token: task_token,
          cause: Temporalio::Api::Enums::V1::WorkflowTaskFailedCause::WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE,
          exception: error,
          binary_checksum: binary_checksum
        )
      rescue StandardError => e
        Temporal.logger.error('Unable to fail Workflow task', metadata.to_h.merge(error: e.inspect))

        Temporal::ErrorHandler.handle(e, config, metadata: metadata)
      end
    end
  end
end
