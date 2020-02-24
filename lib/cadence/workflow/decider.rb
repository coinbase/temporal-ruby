require 'cadence/workflow/executor'
require 'cadence/workflow/history'
require 'cadence/workflow/serializer'

module Cadence
  class Workflow
    # TODO: DecisionTaskProcessor?
    class Decider
      def initialize(workflow_lookup, client)
        @workflow_lookup = workflow_lookup
        @client = client
      end

      def process(decision_task)
        task_token = decision_task.taskToken
        workflow_name = decision_task.workflowType.name

        Cadence.logger.info("Processing a decision task for #{workflow_name}")

        workflow_klass = workflow_lookup.find(workflow_name)

        unless workflow_klass
          Cadence.logger.error("Workflow #{workflow_name} does not exist")
          fail_task(task_token, 'Workflow does not exist')

          return
        end

        history = Workflow::History.new(decision_task.history.events)
        # TODO: For sticky workflows we need to cache the Executor instance
        executor = Workflow::Executor.new(workflow_klass, history)
        decisions = executor.run

        Cadence.logger.debug("Flushing decisions: #{decisions.map(&:last)}")

        complete_task(task_token, decisions)
      rescue StandardError => error
        Cadence.logger.error("Decider failed to process #{decision_task.workflowExecution.workflowId}: #{error.inspect}")
        Cadence.logger.debug(error.backtrace.join("\n"))
      end

      private

      attr_reader :workflow_lookup, :client

      def serialize_decisions(decisions)
        decisions.map { |(_, decision)| Workflow::Serializer.serialize(decision) }
      end

      def complete_task(task_token, decisions)
        client.respond_decision_task_completed(
          task_token: task_token,
          decisions: serialize_decisions(decisions)
        )
      end

      def fail_task(task_token, message)
        client.respond_decision_task_failed(
          task_token: task_token,
          cause: CadenceThrift::DecisionTaskFailedCause::UNHANDLED_DECISION,
          details: { message: message }
        )
      end
    end
  end
end
