require 'workflows/schedule_child_workflow'
require 'workflows/hello_world_workflow'

describe ScheduleChildWorkflow, :integration do
  let(:cron_schedule) { "*/6 * * * *" }

  it 'schedules a child workflow with a given cron schedule' do
    child_workflow_id = 'schedule_child_test_wf-' + SecureRandom.uuid
    workflow_id, run_id = run_workflow(
      described_class,
      child_workflow_id,
      cron_schedule,
      options: {
        timeouts: { execution: 10 }
      }
    )

    # Giving the parent workflow sufficient time to run and schedule the child
    sleep 2

    history_response = fetch_history(child_workflow_id, nil)
    expect(
      history_response.history.events.first.workflow_execution_started_event_attributes.cron_schedule
    ).to eq(cron_schedule)

    Temporal.signal_workflow(described_class, 'finish', workflow_id, run_id)

    wait_for_workflow_completion(workflow_id, run_id)

    # Expecting the child workflow to terminate as a result of the parent close policy
    expect do
      Temporal.await_workflow_result(
        HelloWorldWorkflow,
        workflow_id: child_workflow_id
      )
    end.to raise_error(Temporal::WorkflowTerminated)

  end
end
