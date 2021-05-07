require 'fiber'

require 'temporal/workflow/dispatcher'
require 'temporal/workflow/state_manager'
require 'temporal/workflow/context'
require 'temporal/workflow/history/event_target'

module Temporal
  class Workflow
    class Executor
      def initialize(workflow_class, history)
        @workflow_class = workflow_class
        @dispatcher = Dispatcher.new
        @state_manager = StateManager.new(dispatcher)
        @history = history
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

      attr_reader :workflow_class, :dispatcher, :state_manager, :history

      def execute_workflow(input, metadata)
        context = Workflow::Context.new(state_manager, dispatcher, workflow_class, metadata)

        Fiber.new do
          workflow_class.execute_in_context(context, input)
        end.resume
      end
    end
  end
end
