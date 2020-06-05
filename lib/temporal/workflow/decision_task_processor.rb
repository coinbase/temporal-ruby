require 'temporal/workflow/executor'
require 'temporal/workflow/history'
require 'temporal/workflow/serializer'
require 'temporal/metadata'

module Temporal
  class Workflow
    class DecisionTaskProcessor
      def initialize(task, domain, workflow_lookup, client, middleware_chain)
        @task = task
        @domain = domain
        @task_token = task.taskToken
        @workflow_name = task.workflowType.name
        @workflow_class = workflow_lookup.find(workflow_name)
        @client = client
        @middleware_chain = middleware_chain
      end

      def process
        start_time = Time.now

        Temporal.logger.info("Processing a decision task for #{workflow_name}")
        Temporal.metrics.timing('decision_task.queue_time', queue_time_ms, workflow: workflow_name)

        unless workflow_class
          fail_task('Workflow does not exist')
          return
        end

        history = Workflow::History.new(task.history.events)
        # TODO: For sticky workflows we need to cache the Executor instance
        executor = Workflow::Executor.new(workflow_class, history)
        metadata = Metadata.generate(Metadata::DECISION_TYPE, task, domain)

        decisions = middleware_chain.invoke(metadata) do
          executor.run
        end

        complete_task(decisions)
      rescue StandardError => error
        Temporal.logger.error("Decison task for #{workflow_name} failed with: #{error.inspect}")
        Temporal.logger.debug(error.backtrace.join("\n"))
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing('decision_task.latency', time_diff_ms, workflow: workflow_name)
        Temporal.logger.debug("Decision task processed in #{time_diff_ms}ms")
      end

      private

      attr_reader :task, :domain, :task_token, :workflow_name, :workflow_class, :client, :middleware_chain

      def queue_time_ms
        ((task.startedTimestamp - task.scheduledTimestamp) / 1_000_000).round
      end

      def serialize_decisions(decisions)
        decisions.map { |(_, decision)| Workflow::Serializer.serialize(decision) }
      end

      def complete_task(decisions)
        Temporal.logger.info("Decision task for #{workflow_name} completed")

        client.respond_decision_task_completed(
          task_token: task_token,
          decisions: serialize_decisions(decisions)
        )
      end

      def fail_task(message)
        Temporal.logger.error("Decision task for #{workflow_name} failed with: #{message}")

        client.respond_decision_task_failed(
          task_token: task_token,
          cause: TemporalThrift::DecisionTaskFailedCause::UNHANDLED_DECISION,
          details: { message: message }
        )
      end
    end
  end
end
