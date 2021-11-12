require 'activities/echo_activity'
require 'activities/long_running_activity'

# This example workflow exercises all three conditions that can change state that is being
# awaited upon: activity completion, sleep completion, signal receieved.
class WaitForWorkflow < Temporal::Workflow
  def execute(total_echos, max_echos_at_once, expected_signal)
    signals_received = {}

    workflow.on_signal do |signal, input|
      signals_received[signal] = input
    end

    workflow.wait_for do
      workflow.logger.info("Awaiting #{expected_signal}, signals received so far: #{signals_received}")
      signals_received.key?(expected_signal)
    end

    # Run an activity but with a max time limit by starting a timer. This activity
    # will not complete before the timer, which may result in a failed activity task after the
    # workflow is completed.
    long_running_future = LongRunningActivity.execute(15, 0.1)
    timeout_timer = workflow.start_timer(1)
    workflow.wait_for(timeout_timer, long_running_future)

    timer_beat_activity = timeout_timer.finished? && !long_running_future.finished?

    # This should not wait further. The first future has already finished, and therefore
    # the second one should not be awaited upon.
    long_timeout_timer = workflow.start_timer(15)
    workflow.wait_for(timeout_timer, long_timeout_timer)
    raise 'The workflow should not have waited for this timer to complete' if long_timeout_timer.finished?

    block_called = false
    workflow.wait_for(timeout_timer) do
      # This should never be called because the timeout_timer future was already
      # finished before the wait was even called.
      block_called = true
    end
    raise 'Block should not have been called' if block_called

    workflow.wait_for(long_timeout_timer) do
      # This condition will immediately be true and not result in any waiting or dispatching
      true
    end
    raise 'The workflow should not have waited for this timer to complete' if long_timeout_timer.finished?

    activity_futures = {}
    echos_completed = 0

    total_echos.times do |i|
      workflow.wait_for do
        workflow.logger.info("Activities in flight #{activity_futures.length}")
        # Pause workflow until the number of active activity futures is less than 2. This
        # will throttle new activities from being started, guaranteeing that only two of these
        # activities are running at once.
        activity_futures.length < max_echos_at_once
      end

      future = EchoActivity.execute("hi #{i}")
      activity_futures[i] = future

      future.done do
        activity_futures.delete(i)
        echos_completed += 1
      end
    end

    workflow.wait_for do
      workflow.logger.info("Waiting for queue to drain, size: #{activity_futures.length}")
      activity_futures.empty?
    end

    {
      signal: signals_received.key?(expected_signal),
      timer: timer_beat_activity,
      activity: echos_completed == total_echos
    }
  end
end
