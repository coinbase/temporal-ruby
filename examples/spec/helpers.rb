require 'securerandom'

module Helpers
  def run_workflow(workflow, *input, **args)
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      workflow,
      *input,
      **args.merge(options: { workflow_id: workflow_id })
    )

    client = Temporal.send(:client)

    result = client.get_workflow_execution_history(
      namespace: Temporal.configuration.namespace,
      workflow_id: workflow_id,
      run_id: run_id,
      next_page_token: nil,
      wait_for_new_event: true,
      event_type: :close
    )
  end
end
