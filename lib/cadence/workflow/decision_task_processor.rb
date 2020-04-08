require 'cadence/workflow/executor'
require 'cadence/workflow/history'
require 'cadence/workflow/serializer'

module Cadence
  class Workflow
    class DecisionTaskProcessor
      def initialize(task, workflow_lookup, client, middleware_chain)
        @task = task
        @task_token = task.taskToken
        @workflow_name = task.workflowType.name
        @workflow_class = workflow_lookup.find(workflow_name)
        @client = client
        @middleware_chain = middleware_chain
      end

      def process
        start_time = Time.now

        Cadence.logger.info("Processing a decision task for #{workflow_name}")
        Cadence.metrics.timing('decision_task.queue_time', queue_time_ms, workflow: workflow_name)

        unless workflow_class
          fail_task('Workflow does not exist')
          return
        end

        history = Workflow::History.new(task.history.events)
        # TODO: For sticky workflows we need to cache the Executor instance
        executor = Workflow::Executor.new(workflow_class, history)

        decisions = middleware_chain.invoke(task) do
          executor.run
        end

        complete_task(decisions)
      rescue StandardError => error
        Cadence.logger.error("Decison task for #{workflow_name} failed with: #{error.inspect}")
        Cadence.logger.debug(error.backtrace.join("\n"))
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Cadence.metrics.timing('decision_task.latency', time_diff_ms, workflow: workflow_name)
        Cadence.logger.debug("Decision task processed in #{time_diff_ms}ms")
      end

      private

      attr_reader :task, :task_token, :workflow_name, :workflow_class, :client, :middleware_chain

      def queue_time_ms
        ((task.startedTimestamp - task.scheduledTimestamp) / 1_000_000).round
      end

      def serialize_decisions(decisions)
        decisions.map { |(_, decision)| Workflow::Serializer.serialize(decision) }
      end

      def complete_task(decisions)
        Cadence.logger.info("Decision task for #{workflow_name} completed")

        client.respond_decision_task_completed(
          task_token: task_token,
          decisions: serialize_decisions(decisions)
        )
      end

      def fail_task(message)
        Cadence.logger.error("Decision task for #{workflow_name} failed with: #{message}")

        client.respond_decision_task_failed(
          task_token: task_token,
          cause: CadenceThrift::DecisionTaskFailedCause::UNHANDLED_DECISION,
          details: { message: message }
        )
      end
    end
  end
end
