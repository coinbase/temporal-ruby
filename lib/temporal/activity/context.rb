# This context class is available in the activity implementation
# and provides context and methods for interacting with Temporal
#
require 'temporal/errors'
require 'temporal/uuid'
require 'temporal/activity/async_token'

module Temporal
  class Activity
    class Context
      def initialize(connection, metadata, config, heartbeat_thread_pool, is_shutting_down)
        @connection = connection
        @metadata = metadata
        @config = config
        @heartbeat_thread_pool = heartbeat_thread_pool
        @last_heartbeat_details = [] # an array to differentiate nil hearbeat from no heartbeat queued
        @heartbeat_check_scheduled = nil
        @heartbeat_mutex = Mutex.new
        @async = false
        @cancel_requested = false
        @last_heartbeat_throttled = false
        @is_shutting_down = is_shutting_down
      end

      attr_reader :heartbeat_check_scheduled, :last_heartbeat_throttled

      def async
        @async = true
      end

      def async?
        @async
      end

      def async_token
        AsyncToken.encode(
          metadata.namespace,
          metadata.id,
          metadata.workflow_id,
          metadata.workflow_run_id
        )
      end

      # Returns true if the activity has been canceled directly by its workflow or indirectly by
      # its workflow being terminated. This will only be set following a call to heartbeat that is
      # not throttled.
      def cancel_requested
        @cancel_requested
      end

      # Returns true if the activity has breached its start-to-close or schedule-to-close timeout
      def timed_out?
        deadline_exceeded?(start_to_close_deadline) || deadline_exceeded?(schedule_to_close_deadline)
      end

      # This returns true if the worker has started shutting down upon receiving a
      # TERM or INT signal. Once this happens, your activity should finishing processing
      # quickly or raise an error to fail the activity attempt.
      def shutting_down?
        @is_shutting_down.call
      end

      # Send an activity heartbeat using an optional details payload
      def heartbeat(details = nil)
        logger.debug('Activity heartbeat', metadata.to_h)

        # Heartbeat throttling limits the number of calls made to Temporal server, reducing load on the server
        # and improving activity performance. The first heartbeat in an activity will always be sent immediately.
        # After that, a timer is scheduled on a background thread. While this check heartbeat thread is scheduled,
        # heartbeats will not be directly sent to the server, but rather the value will be saved for later. When
        # this timer fires and the thread resumes, it will send any heartbeats that came in while waiting, and
        # begin the process over again.
        #
        # The interval is determined by the following criteria:
        # - if a heartbeat timeout is set, 80% of it
        # - or if there is no heartbeat timeout set, use the configuration for default_heartbeat_throttle_interval
        # - any duration is capped by the max_heartbeat_throttle_interval configuration
        #
        # Example:
        # Assume a heartbeat timeout of 10s
        # Throttle interval will be 8s, below the 60s maximum interval cap
        # Assume the following timeline:
        # t = 0, heartbeat, sent, timer scheduled for 8s
        # t = 1, heartbeat, saved
        # t = 6, heartbeat, saved
        # t = 8, timer wakes up, sends the saved heartbeat from t = 6, new timer scheduled for 16s
        # ... no heartbeats
        # t = 16, timer wakes up, no saved hearbeat to send, no new timer scheduled
        # t = 20, heartbeat, sent, timer scheduled for 28s
        # ...

        heartbeat_mutex.synchronize do
          if heartbeat_check_scheduled.nil?
            send_heartbeat(details)
            @last_heartbeat_details = []
            @last_heartbeat_throttled = false
            @heartbeat_check_scheduled = schedule_check_heartbeat(heartbeat_throttle_interval)
          else
            logger.debug('Throttling heartbeat for sending later', metadata.to_h)
            @last_heartbeat_details = [details]
            @last_heartbeat_throttled = true
          end
        end

        # Return back the context so that .cancel_requested works similarly to before when the
        # GRPC response was returned back directly
        self
      end

      # Like heartbeat, but a subclass of ActivityInterrupted error will be raised if the
      # activity has been canceled, start-to-close timeout exceeded, or if the worker is
      # shutting down. This flag defaults to false, in which these states can be detected by
      # inspecting the heartbeat response for cancelation, or calling timed_out? or shutting_down?
      # methods.
      def heartbeat_interrupted(details = nil)
        if deadline_exceeded?(schedule_to_close_deadline)
          raise ActivityExecutionTimedOut,
                "Activity schedule-to-close timeout of #{metadata.schedule_to_close_timeout} exceeded"
        end

        if deadline_exceeded?(start_to_close_deadline)
          raise ActivityExecutionTimedOut,
                "Activity start-to-close timeout of #{metadata.start_to_close_timeout} exceeded"
        end

        heartbeat(details)

        raise ActivityExecutionCanceled, 'Activity cancellation requested by server' if cancel_requested
        raise ActivityWorkerShuttingDown, 'Worker is shutting down' if shutting_down?
      end

      def heartbeat_details
        metadata.heartbeat_details
      end

      def logger
        Temporal.logger
      end

      def run_idem
        UUID.v5(metadata.workflow_run_id.to_s, metadata.id.to_s)
      end
      alias idem run_idem

      def workflow_idem
        UUID.v5(metadata.workflow_id.to_s, metadata.id.to_s)
      end

      def headers
        metadata.headers
      end

      # The name of the activity's class.  In a dynamic Activity, it may be the name
      # of a class or a key to an executor you want to delegate to.
      def name
        metadata.name
      end

      private

      attr_reader :connection, :metadata, :heartbeat_thread_pool, :config, :heartbeat_mutex, :last_heartbeat_details

      def task_token
        metadata.task_token
      end

      def heartbeat_throttle_interval
        # This is a port of logic in the Go SDK
        # https://github.com/temporalio/sdk-go/blob/eaa3802876de77500164f80f378559c51d6bb0e2/internal/internal_task_handlers.go#L1990
        interval = if metadata.heartbeat_timeout > 0
          metadata.heartbeat_timeout * 0.8
        else
          config.timeouts[:default_heartbeat_throttle_interval]
        end

        [interval, config.timeouts[:max_heartbeat_throttle_interval]].min
      end

      def send_heartbeat(details)
        begin
          response = connection.record_activity_task_heartbeat(
            namespace: metadata.namespace,
            task_token: task_token,
            details: details)
          if response.cancel_requested
            logger.info('Activity has been canceled', metadata.to_h)
            @cancel_requested = true
          end
        rescue => error
          Temporal::ErrorHandler.handle(error, config, metadata: metadata)
          raise
        end
      end

      def schedule_check_heartbeat(delay)
        return nil if delay <= 0

        heartbeat_thread_pool.schedule([metadata.workflow_run_id, metadata.id, metadata.attempt], delay) do
          details = heartbeat_mutex.synchronize do
            @heartbeat_check_scheduled = nil
            # Check to see if there is a saved heartbeat. If heartbeat was not called while this was waiting,
            # this will be empty and there's no need to send anything or to scheduled another heartbeat
            # check.
            last_heartbeat_details
          end
          begin
            unless details.empty?
              heartbeat(details.first)
            end
          rescue
            # Can swallow any errors here since this only runs on a background thread. Any error will be
            # sent to the error handler above in send_heartbeat.
          end
        end
      end

      def start_to_close_deadline
        if metadata.start_to_close_timeout.positive?
          metadata.started_at + metadata.start_to_close_timeout
        else
          nil
        end
      end

      def schedule_to_close_deadline
        if metadata.schedule_to_close_timeout.positive?
          metadata.scheduled_at + metadata.schedule_to_close_timeout
        else
          nil
        end
      end

      def deadline_exceeded?(deadline)
        !deadline.nil? && Time.now > deadline
      end
    end
  end
end
