module Temporal
  module Schedule
    class ScheduleState
      attr_reader :notes, :paused, :limited_actions, :remaining_actions

      # @param notes [String] Human-readable notes about the schedule.
      # @param paused [Boolean] If true, do not take any actions based on the schedule spec.
      # @param limited_actions [Boolean] If true, decrement remaining_actions when an action is taken.
      # @param remaining_actions [Integer] The number of actions remaining to be taken.
      def initialize(notes: nil, paused: nil, limited_actions: nil, remaining_actions: nil)
        @notes = notes
        @paused = paused
        @limited_actions = limited_actions
        @remaining_actions = remaining_actions
      end
    end
  end
end
