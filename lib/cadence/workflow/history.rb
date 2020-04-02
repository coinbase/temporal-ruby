require 'cadence/workflow/history/event'
require 'cadence/workflow/history/window'

module Cadence
  class Workflow
    class History
      attr_reader :events

      def initialize(events)
        @events = events.map { |event| History::Event.new(event) }
        @iterator = @events.each
      end

      def last_completed_decision_task
        events.select { |event| event.type == 'DecisionTaskCompleted' }.last
      end

      # It is very important to replay the History window by window in order to
      # simulate the exact same state the workflow was in when it processed the
      # decision task for the first time.
      #
      # A history window consists of 3 parts:
      #
      # 1. Events that happened since the last window (timer fired, activity completed, etc)
      # 2. A decision task related events (decision task started, completed, failed, etc)
      # 3. Commands issued by the last decision task (^) (schedule activity, start timer, etc)
      #
      def next_window
        return unless peek_event

        window = History::Window.new

        while event = next_event
          window.add(event)

          break if event.type == 'DecisionTaskCompleted'
        end

        # Find the end of the window by exhausting all the commands
        window.add(next_event) while command?(peek_event)

        window.freeze
      end

      private

      COMMAND_EVENT_TYPES = %w[
        ActivityTaskScheduled
        ActivityTaskCancelRequested
        TimerStarted
        CancelTimerFailed
        TimerCanceled
        WorkflowExecutionCancelRequested
        StartChildWorkflowExecutionInitiated
        SignalExternalWorkflowExecutionInitiated
        RequestCancelActivityTaskFailed
        RequestCancelExternalWorkflowExecutionInitiated
        MarkerRecorded
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
