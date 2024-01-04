module Temporal
  module Schedule
    class Backfill
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

      # The time to start the backfill
      attr_reader :start_time

      # The time to end the backfill
      attr_reader :end_time

      # @param start_time [Time] The time to start the backfill
      # @param end_time [Time] The time to end the backfill
      # @param overlap_policy [Time] Should be one of :skip, :buffer_one, :buffer_all, :cancel_other, :terminate_other, :allow_all
      def initialize(start_time: nil, end_time: nil, overlap_policy: nil)
        @start_time = start_time
        @end_time = end_time
        @overlap_policy = overlap_policy
      end
    end
  end
end
