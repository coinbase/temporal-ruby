class QuickTimeoutWorkflow < Temporal::Workflow
  timeouts run: 0.1

  def execute
    sleep(1) # more than the run timeout
  end
end
