require 'fiber'

require 'temporal/workflow/dispatcher'
require 'temporal/workflow/query_registry'
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
        @query_registry = QueryRegistry.new
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

      # Process queries using the pre-registered query handlers
      #
      # @note this method is expected to be executed after the history has
      #   been fully replayed (by invoking the #run method)
      #
      # @param query [Hash<String, Temporal::Workflow::TaskProcessor::Query>]
      #
      # @return [Hash<String, Temporal::Workflow::QueryResult>]
      def process_queries(queries = {})
        queries.transform_values(&method(:process_query))
      end

      private

      attr_reader :workflow_class, :dispatcher, :query_registry, :state_manager, :task_metadata, :history, :config

      def process_query(query)
        result = query_registry.handle(query.query_type, query.query_args)

        QueryResult.answer(result)
      rescue StandardError => error
        QueryResult.failure(error)
      end

      def execute_workflow(input, workflow_started_event)
        metadata = Metadata.generate_workflow_metadata(workflow_started_event, task_metadata)
        context = Workflow::Context.new(state_manager, dispatcher, workflow_class, metadata, config, query_registry)

        Fiber.new do
          workflow_class.execute_in_context(context, input)
        end.resume
      end
    end
  end
end
