require 'fiber'

require 'temporal/workflow/dispatcher'
require 'temporal/workflow/state_manager'
require 'temporal/workflow/context'
require 'temporal/workflow/history/event_target'
require 'temporal/metadata'

module Temporal
  class Workflow
    class Executor
      def initialize(workflow_class, history, metadata, config)
        @workflow_class = workflow_class
        @dispatcher = Dispatcher.new
        @state_manager = StateManager.new(dispatcher)
        @metadata = metadata
        @history = history
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

      private

      attr_reader :workflow_class, :dispatcher, :state_manager, :metadata, :history, :config

      def execute_workflow(input, workflow_started_event_attributes)
        metadata = generate_workflow_metadata_from(workflow_started_event_attributes)
        context = Workflow::Context.new(state_manager, dispatcher, workflow_class, metadata, config)

        Fiber.new do
          workflow_class.execute_in_context(context, input)
        end.resume
      end

      # workflow_id and domain are confusingly not available on the WorkflowExecutionStartedEvent,
      # so we have to fetch these from the DecisionTask's metadata
      def generate_workflow_metadata_from(event_attributes)
        Metadata::Workflow.new(
          namespace: metadata.namespace,
          id: metadata.workflow_id,
          name: event_attributes.workflow_type.name,
          run_id: event_attributes.original_execution_run_id,
          attempt: event_attributes.attempt,
          headers: event_attributes.header&.fields || {}
        )
      end
    end
  end
end
