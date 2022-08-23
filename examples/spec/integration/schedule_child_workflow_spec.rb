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

    wait_for_workflow_completion(workflow_id, run_id)
    parent_history = fetch_history(workflow_id, run_id)

    child_workflow_event = parent_history.history.events.detect do |event|
      event.event_type == :EVENT_TYPE_START_CHILD_WORKFLOW_EXECUTION_INITIATED
    end
    expect(
      child_workflow_event.start_child_workflow_execution_initiated_event_attributes.cron_schedule
    ).to eq(cron_schedule)

    # Expecting the child workflow to terminate as a result of the parent close policy
    expect do
      Temporal.await_workflow_result(
        HelloWorldWorkflow,
        workflow_id: child_workflow_id
      )
    end.to raise_error(Temporal::WorkflowTerminated)

  end
end
