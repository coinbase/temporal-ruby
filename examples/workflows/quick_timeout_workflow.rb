class QuickTimeoutWorkflow < Temporal::Workflow
  timeouts run: 0.1

  def execute
    sleep(0.2) # more than the run timeout
  end
end
