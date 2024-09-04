require "temporal/schedule/schedule"
require "temporal/schedule/calendar"
require "temporal/schedule/schedule_spec"
require "temporal/schedule/schedule_policies"
require "temporal/schedule/schedule_state"
require "temporal/schedule/start_workflow_action"

describe "Temporal.pause_schedule", :integration do
  let(:example_schedule) do
    Temporal::Schedule::Schedule.new(
      spec: Temporal::Schedule::ScheduleSpec.new(
        cron_expressions: ["@hourly"],
        # Set an end time so that the test schedule doesn't run forever
        end_time: Time.now + 600
      ),
      action: Temporal::Schedule::StartWorkflowAction.new(
        "HelloWorldWorkflow",
        "Test",
        options: {
          task_queue: integration_spec_task_queue
        }
      )
    )
  end

  it "can pause and unpause a schedule" do
    namespace = integration_spec_namespace
    schedule_id = SecureRandom.uuid

    Temporal.create_schedule(namespace, schedule_id, example_schedule)
    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.state.paused).to(eq(false))

    Temporal.pause_schedule(namespace, schedule_id)

    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.state.paused).to(eq(true))

    Temporal.unpause_schedule(namespace, schedule_id)

    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.state.paused).to(eq(false))
  end
end
