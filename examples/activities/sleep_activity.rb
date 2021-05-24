class SleepActivity < Temporal::Activity
  timeouts(
    schedule_to_close: 300,
    start_to_close: 300,
  )

  # timeout can be up to schedule_to_close seconds
  def execute(timeout)
    sleep timeout
  end
end
