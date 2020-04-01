require 'fiber'

require 'cadence/workflow/dispatcher'
require 'cadence/workflow/state_manager'
require 'cadence/workflow/context'
require 'cadence/workflow/history/event_target'

module Cadence
  class Workflow
    class Executor
      def initialize(workflow_class, history)
        @workflow_class = workflow_class
        @dispatcher = Dispatcher.new
        @state_manager = StateManager.new(dispatcher)
        @history = history
        @new_decisions = []
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

        return state_manager.decisions
      end

      private

      attr_reader :workflow_class, :dispatcher, :state_manager, :history, :new_decisions

      def execute_workflow(input, metadata)
        context = Workflow::Context.new(state_manager, dispatcher, metadata)

        Fiber.new do
          workflow_class.execute_in_context(context, input)
        end.resume
      end
    end
  end
end
