require 'activities/echo_activity'
require 'activities/long_running_activity'

# This example workflow exercises all three conditions that can change state that is being
# awaited upon: activity completion, sleep completion, signal receieved.
class AwaitWorkflow < Temporal::Workflow
  def execute(expected_signal)
    signals_received = {}

    workflow.on_signal do |signal, input|
      signals_received[signal] = input
    end

    workflow.await do
      workflow.logger.info("Awaiting #{expected_signal}, signals received so far: #{signals_received}")
      signals_received.key?(expected_signal)
    end

    # Run an activity but with a max time limit by starting a timer. This activity
    # will not complete before the timer, which may result in a failed activity task after the
    # workflow is completed.
    long_running_future = LongRunningActivity.execute(15, 0.1)
    timeout_timer = workflow.start_timer(1)
    workflow.await do
      long_running_future.finished? || timeout_timer.finished?
    end

    timer_beat_activity = timeout_timer.finished? && !long_running_future.finished?

    activity_futures = {}
    echos_completed = 0

    10.times do |i|
      workflow.await do
        workflow.logger.info("Activities in flight #{activity_futures.length}")
        activity_futures.length < 2
      end

      future = EchoActivity.execute("hi #{i}")
      future.done do
        activity_futures.delete(i)
        echos_completed += 1
      end

      activity_futures[i] = future
    end

    workflow.await do
      workflow.logger.info("Waiting for queue to drain, size: #{activity_futures.length}")
      activity_futures.empty?
    end

    workflow.await do
      # This condition will immediately be true and not result in any waiting or dispatching
      true
    end

    {
      signal: signals_received.key?(expected_signal),
      timer: timer_beat_activity,
      activity: echos_completed == 10
    }
  end
end
