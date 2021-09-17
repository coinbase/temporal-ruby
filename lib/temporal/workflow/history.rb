require 'temporal/workflow/history/event'
require 'temporal/workflow/history/window'

module Temporal
  class Workflow
    class History
      attr_reader :events

      def initialize(events)
        @events = events.map { |event| History::Event.new(event) }
        @iterator = @events.each
      end

      def find_event_by_id(id)
        events.find { |event| event.id == id }
      end

      # It is very important to replay the History window by window in order to
      # simulate the exact same state the workflow was in when it processed the
      # workflow task for the first time.
      #
      # A history window consists of 3 parts:
      #
      # 1. Events that happened since the last window (timer fired, activity completed, etc)
      # 2. A workflow task related events (workflow task started, completed, failed, etc)
      # 3. Commands issued by the last workflow task (^) (schedule activity, start timer, etc)
      #
      def next_window
        return unless peek_event

        window = History::Window.new

        while event = next_event
          window.add(event)

          break if event.type == 'WORKFLOW_TASK_COMPLETED'
        end

        # Find the end of the window by exhausting all the commands
        window.add(next_event) while command?(peek_event)

        window.freeze
      end

      private

      COMMAND_EVENT_TYPES = %w[
        ACTIVITY_TASK_SCHEDULED
        ACTIVITY_TASK_CANCEL_REQUESTED
        TIMER_STARTED
        CANCEL_TIMER_FAILED
        TIMER_CANCELED
        WORKFLOW_EXECUTION_CANCEL_REQUESTED
        START_CHILD_WORKFLOW_EXECUTION_INITIATED
        SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED
        REQUEST_CANCEL_ACTIVITY_TASK_FAILED
        REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_INITIATED
        MARKER_RECORDED
      ].freeze

      attr_reader :iterator

      def next_event
        iterator.next rescue nil
      end

      def peek_event
        iterator.peek rescue nil
      end

      def command?(event)
        COMMAND_EVENT_TYPES.include?(event&.type)
      end
    end
  end
end
