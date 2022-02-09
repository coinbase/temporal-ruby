# One workflow sends a signal to another workflow.
#
class WaitForExternalSignalWorkflow < Temporal::Workflow
  def execute(expected_signal)
    signals_received = {}

    workflow.on_signal do |signal, input|
      workflow.logger.info("Received signal name #{signal}, with input #{input.inspect}")
      signals_received[signal] = input
    end

    workflow.wait_for do
      workflow.logger.info("Awaiting #{expected_signal}, signals received so far: #{signals_received}")
      signals_received.key?(expected_signal)
    end

    timeout_timer = workflow.start_timer(1)
    workflow.wait_for(timeout_timer)

    signals_received
  end
end

class SendSignalToExternalWorkflow < Temporal::Workflow
  def execute(signal_name, target_workflow)
    logger.info("Send a signal to an external workflow")
    future = workflow.signal_external_workflow(WaitForExternalSignalWorkflow, signal_name, "arg1", "arg2", options: {workflow_id: target_workflow} )
    future.get
  end
end
