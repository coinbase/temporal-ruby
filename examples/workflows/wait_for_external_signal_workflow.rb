# One workflow sends a signal to another workflow. Can be used to implement
# the synchronous-proxy pattern (see Go samples)
#
class WaitForExternalSignalWorkflow < Temporal::Workflow
  def execute(expected_signal)
    signals_received = {}
    signal_counts = Hash.new { |h,k| h[k] = 0 }

    workflow.on_signal do |signal, input|
      workflow.logger.info("Received signal name #{signal}, with input #{input.inspect}")
      signals_received[signal] = input
      signal_counts[signal] += 1
    end

    workflow.wait_until do
      workflow.logger.info("Awaiting #{expected_signal}, signals received so far: #{signals_received}")
      signals_received.key?(expected_signal)
    end

    { received: signals_received, counts: signal_counts }
  end
end
