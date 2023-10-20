require 'activities/hello_world_activity'

class SignalWithStartWorkflow < Temporal::Workflow

  def execute(expected_signal)
    initial_value = 'no signal received'
    received = initial_value

    workflow.on_signal do |signal, input|
      if signal == expected_signal
        HelloWorldActivity.execute!('expected signal')
        received = input
      end
    end

    # Wait for the activity in signal callbacks to complete. The workflow will
    # not automatically wait for any blocking calls made in callbacks to complete
    # before returning.
    workflow.wait_until { received != initial_value }
    received
  end
end
