require "temporal/errors"
require "temporal/schedule/schedule"
require "temporal/schedule/schedule_spec"
require "temporal/schedule/start_workflow_action"

describe "Temporal.delete_schedule", :integration do
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
          task_queue: Temporal.configuration.task_queue
        }
      )
    )
  end

  it "can delete schedules" do
    namespace = integration_spec_namespace

    schedule_id = SecureRandom.uuid

    Temporal.create_schedule(namespace, schedule_id, example_schedule)
    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.action.start_workflow.workflow_type.name).to(eq("HelloWorldWorkflow"))

    Temporal.delete_schedule(namespace, schedule_id)

    # Now that the schedule is delted it should raise a not found error
    expect do
      Temporal.describe_schedule(namespace, schedule_id)
    end
      .to(raise_error(Temporal::NotFoundFailure))
  end

  it "raises a NotFoundFailure if a schedule doesn't exist" do
    namespace = integration_spec_namespace

    expect do
      Temporal.delete_schedule(namespace, "some-invalid-schedule-id")
    end
      .to(raise_error(Temporal::NotFoundFailure))
  end
end
