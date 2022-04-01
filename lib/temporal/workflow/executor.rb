require 'fiber'

require 'temporal/workflow/dispatcher'
require 'temporal/workflow/state_manager'
require 'temporal/workflow/context'
require 'temporal/workflow/history/event_target'
require 'temporal/metadata'

module Temporal
  class Workflow
    class Executor
      # @param workflow_class [Class]
      # @param history [Workflow::History]
      # @param task_metadata [Metadata::WorkflowTask]
      # @param config [Configuration]
      def initialize(workflow_class, history, task_metadata, config)
        @workflow_class = workflow_class
        @dispatcher = Dispatcher.new
        @state_manager = StateManager.new(dispatcher)
        @history = history
        @task_metadata = task_metadata
        @config = config
      end

      def run
        dispatcher.register_handler(
          History::EventTarget.workflow,
          'started',
          &method(:execute_workflow)
        )

        while window = history.next_window
          state_manager.apply(window)
        end

        return state_manager.commands
      end

      # @param query [Hash<String, Temporal::Workflow::TaskProcessor::Query>]
      #
      # @return [Hash<String, Temporal::Workflow::QueryResult>]
      def process_queries(queries = {})
        queries.transform_values(&method(:process_query))
      end

      private

      attr_reader :workflow_class, :dispatcher, :state_manager, :task_metadata, :history, :config, :context

      def process_query(query)
        unless context.query_handlers.key?(query.query_type)
          raise Temporal::QueryFailedFailure, "Workflow did not register a handler for #{query.query_type}"
        end

        result = context.query_handlers[query.query_type].call(*query.query_args)
        QueryResult.answer(result)
      rescue StandardError => error
        QueryResult.failure(error)
      end

      def execute_workflow(input, workflow_started_event)
        metadata = Metadata.generate_workflow_metadata(workflow_started_event, task_metadata)
        @context = Workflow::Context.new(state_manager, dispatcher, workflow_class, metadata, config)

        Fiber.new do
          workflow_class.execute_in_context(context, input)
        end.resume
      end
    end
  end
end
