module Temporal
  module Schedule
    class SchedulePolicies
      # Controls what happens when a workflow would be started
      # by a schedule, and is already running.
      #
      # If provided, must be one of:
      # - :skip (default): means don't start anything. When the  workflow
      #      completes, the next scheduled event after that time will be considered.
      # - :buffer_one: means start the workflow again soon as the
      #      current one completes, but only buffer one start in this way. If
      #      another start is supposed to happen when the workflow is running,
      #      and one is already buffered, then only the first one will be
      #      started after the running workflow finishes.
      # - :buffer_all : means buffer up any number of starts to all happen
      #      sequentially, immediately after the running workflow completes.
      # - :cancel_other: means that if there is another workflow running, cancel
      #      it, and start the new one after the old one completes cancellation.
      # - :terminate_other: means that if there is another workflow running,
      #      terminate it and start the new one immediately.
      # - :allow_all: means start any number of concurrent workflows.
      #      Note that with this policy, last completion result and last failure
      #      will not be available since workflows are not sequential.
      attr_reader :overlap_policy

      # Policy for catchups:
      # If the Temporal server misses an action due to one or more components
      # being down, and comes back up, the action will be run if the scheduled
      # time is within this window from the current time.
      # This value defaults to 60 seconds, and can't be less than 10 seconds.
      attr_reader :catchup_window

      # If true, and a workflow run fails or times out, turn on "paused".
      # This applies after retry policies: the full chain of retries must fail to
      # trigger a pause here.
      attr_reader :pause_on_failure

      # @param overlap_policy [Symbol] Should be one of :skip, :buffer_one, :buffer_all, :cancel_other, :terminate_other, :allow_all
      # @param catchup_window [Integer] The number of seconds to catchup if the Temporal server misses an action
      # @param pause_on_failure [Boolean] Whether to pause the schedule if the action fails
      def initialize(overlap_policy: nil, catchup_window: nil, pause_on_failure: nil)
        @overlap_policy = overlap_policy
        @catchup_window = catchup_window
        @pause_on_failure = pause_on_failure
      end
    end
  end
end
