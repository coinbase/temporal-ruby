class SleepActivity < Temporal::Activity
  timeouts(
    schedule_to_close: 5,
    schedule_to_start: 5,
    start_to_close: 5,
    heartbeat: 5
  )

  def execute(timeout)
    sleep timeout
  end
end
