require 'securerandom'

module Helpers
  def run_workflow(workflow, *input, **args)
    workflow_id = SecureRandom.uuid
    args[:options] = { workflow_id: workflow_id }.merge(args[:options] || {})
    run_id = Temporal.start_workflow(workflow, *input, **args)

    [workflow_id, run_id]
  end

  def wait_for_workflow_completion(workflow_id, run_id)
    fetch_history(
      workflow_id,
      run_id,
      wait_for_new_event: true,
      event_type: :close,
      timeout: 15,
    )
  end

  def fetch_history(workflow_id, run_id, options = {})
    connection = Temporal.send(:default_client).send(:connection)

    connection.get_workflow_execution_history(
      {
        namespace: Temporal.configuration.namespace,
        workflow_id: workflow_id,
        run_id: run_id,
      }.merge(options)
    )
  end

  def integration_spec_namespace
    ENV.fetch('TEMPORAL_NAMESPACE', 'ruby-samples')
  end
end
