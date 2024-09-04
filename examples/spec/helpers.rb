require 'securerandom'

module Helpers
  def run_workflow(workflow, *input, **args)
    args[:options] = { workflow_id: SecureRandom.uuid }.merge(args[:options] || {})
    run_id = Temporal.start_workflow(workflow, *input, **args)

    [args[:options][:workflow_id], run_id]
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
    options = {
      namespace: integration_spec_namespace,
      workflow_id: workflow_id,
      run_id: run_id,
    }.merge(options)

    connection.get_workflow_execution_history(**options)
  end

  def integration_spec_namespace
    ENV.fetch('TEMPORAL_NAMESPACE', DEFAULT_NAMESPACE)
  end

  def integration_spec_task_queue
    ENV.fetch('TEMPORAL_TASK_QUEUE', DEFAULT_TASK_QUEUE)
  end
end
