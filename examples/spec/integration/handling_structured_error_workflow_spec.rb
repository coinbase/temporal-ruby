require 'workflows/handling_structured_error_workflow'

describe HandlingStructuredErrorWorkflow, :integration do
  # This test should be run when a worker with USE_ERROR_SERIALIZATION_V2 is running.
  # That worker runs a task queue, error_serialization_v2.  This setup code will
  # route workflow requests to that task queue.
  around(:each) do |example|
    Temporal.configure do |config|
      config.task_queue = 'error_serialization_v2'
    end

    example.run
  ensure
    Temporal.configure do |config|
      config.task_queue = integration_spec_task_queue
    end
  end

  it 'correctly re-raises an activity-thrown exception in the workflow' do
    workflow_id = SecureRandom.uuid

    Temporal.start_workflow(described_class, 'foo', 5.0, options: { workflow_id: workflow_id })
    begin
      result = Temporal.await_workflow_result(described_class, workflow_id: workflow_id)
      expect(result).to eq('successfully handled error')
    rescue Temporal::ActivityException
      raise "Error deserialization failed.  You probably need to run USE_ERROR_SERIALIZATION_V2=1 ./bin/worker and try again."
    end
  end

end
