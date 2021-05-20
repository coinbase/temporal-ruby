require 'securerandom'

module Helpers
  def run_workflow(workflow, *input, **args)
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      workflow,
      *input,
      **args.merge(options: { workflow_id: workflow_id })
    )

    return workflow_id, run_id
  end

  def wait_for_workflow_completion(workflow_id, run_id)
    fetch_history(
      workflow_id,
      run_id,
      wait_for_new_event: true,
      event_type: :close,
    )
  end

  def fetch_history(workflow_id, run_id, options = {})
    client = Temporal.send(:client)

    result = client.get_workflow_execution_history(
      {
        namespace: Temporal.configuration.namespace,
        workflow_id: workflow_id,
        run_id: run_id,
      }.merge(options)
    )
  end
end
