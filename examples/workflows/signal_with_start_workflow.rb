class SignalWithStartWorkflow < Temporal::Workflow

  def execute(expected_signal, sleep_for)
    received = 'no signal received'

    workflow.on_signal do |signal, input|
      if signal == expected_signal
        received = input
      end
    end

    # Do something to get descheduled so the signal handler has a chance to run
    workflow.sleep(sleep_for)
    received
  end
end
