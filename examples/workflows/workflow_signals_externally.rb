# One workflow sends a signal to another workflow.
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

    workflow.wait_for do
      workflow.logger.info("Awaiting #{expected_signal}, signals received so far: #{signals_received}")
      signals_received.key?(expected_signal)
    end

    { received: signals_received, counts: signal_counts }
  end
end

class SendSignalToExternalWorkflow < Temporal::Workflow
  def execute(signal_name, target_workflow)
    logger.info("Send a signal to an external workflow")
    future = workflow.signal_external_workflow(WaitForExternalSignalWorkflow, signal_name, "arg1", "arg2", options: {workflow_id: target_workflow} )
    @status = nil
    future.done { @status = :success }
    future.failed { @status = :failed }
    future.get
    @status
  end
end
