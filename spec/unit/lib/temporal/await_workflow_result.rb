require 'temporal'
require 'temporal/workflow'

describe 'Temporal.await_workflow_result' do
  class NamespacedWorkflow < Temporal::Workflow
    namespace 'some-namespace'
    task_queue 'some-task-queue'
  end

  let(:client) { instance_double(Temporal::Client::GRPCClient) }
  before { allow(Temporal::Client).to receive(:generate).and_return(client) }
  after { Temporal.remove_instance_variable(:@client) rescue NameError }

  let(:response) do
    Temporal::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse.new(
      history: Temporal::Api::History::V1::History.new(
        events: [
          {
            event_type: :EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED,
            workflow_execution_completed_event_attributes: Temporal::Api::History::V1::WorkflowExecutionCompletedEventAttributes.new(
              result: nil
            )
          }
        ]
      ),
    )
  end

  it 'looks up history in the correct namespace for namespaced workflows' do
    workflow_id = 'dummy_workflow_id'
    run_id = 'dummy_run_id'
    expect(client)
      .to receive(:get_workflow_execution_history)
      .with(
        namespace: 'some-namespace',
        workflow_id: workflow_id,
        run_id: run_id,
        wait_for_new_event: true,
        event_type: :close,
      )
      .and_return(response)

    Temporal.await_workflow_result(
      workflow: NamespacedWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
  end

end
