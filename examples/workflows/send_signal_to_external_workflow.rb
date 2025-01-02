# Sends +signal_name+ to the +target_workflow+ from within a workflow.
# This is different than using the Client#send_signal method which is
# for signaling a workflow *from outside* any workflow.
#
# Returns :success on success, or a specific error message on failure
#
class SendSignalToExternalWorkflow < Temporal::Workflow
  def execute(signal_name, target_workflow)
    logger.info("Send a signal to an external workflow")
    future = workflow.signal_external_workflow(WaitForExternalSignalWorkflow, signal_name, target_workflow, nil, ["arg1", "arg2"])

    status = nil
    future.done { status = :success }
    future.failed { |error| status = error.to_s }
    future.get
    status
  end
end
