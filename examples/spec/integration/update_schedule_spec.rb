require "temporal/errors"
require "temporal/schedule/schedule"
require "temporal/schedule/schedule_spec"
require "temporal/schedule/schedule_policies"
require "temporal/schedule/schedule_state"
require "temporal/schedule/start_workflow_action"

describe "Temporal.update_schedule", :integration do
  let(:example_schedule) do
    Temporal::Schedule::Schedule.new(
      spec: Temporal::Schedule::ScheduleSpec.new(
        cron_expressions: ["@hourly"],
        jitter: 30,
        # Set an end time so that the test schedule doesn't run forever
        end_time: Time.now + 600
      ),
      action: Temporal::Schedule::StartWorkflowAction.new(
        "HelloWorldWorkflow",
        "Test",
        options: {
          task_queue: Temporal.configuration.task_queue
        }
      ),
      policies: Temporal::Schedule::SchedulePolicies.new(
        overlap_policy: :buffer_one
      ),
      state: Temporal::Schedule::ScheduleState.new(
        notes: "Created by integration test"
      )
    )
  end

  let(:updated_schedule) do
    Temporal::Schedule::Schedule.new(
      spec: Temporal::Schedule::ScheduleSpec.new(
        cron_expressions: ["@hourly"],
        jitter: 500,
        # Set an end time so that the test schedule doesn't run forever
        end_time: Time.now + 600
      ),
      action: Temporal::Schedule::StartWorkflowAction.new(
        "HelloWorldWorkflow",
        "UpdatedInput",
        options: {
          task_queue: Temporal.configuration.task_queue
        }
      ),
      policies: Temporal::Schedule::SchedulePolicies.new(
        overlap_policy: :buffer_all
      ),
      state: Temporal::Schedule::ScheduleState.new(
        notes: "Updated by integration test"
      )
    )
  end

  it "can update schedules" do
    namespace = integration_spec_namespace
    schedule_id = SecureRandom.uuid

    Temporal.create_schedule(namespace, schedule_id, example_schedule)

    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.spec.jitter.seconds).to(eq(30))
    expect(describe_response.schedule.policies.overlap_policy).to(eq(:SCHEDULE_OVERLAP_POLICY_BUFFER_ONE))
    expect(describe_response.schedule.action.start_workflow.workflow_type.name).to(eq("HelloWorldWorkflow"))
    expect(describe_response.schedule.state.notes).to(eq("Created by integration test"))

    Temporal.update_schedule(namespace, schedule_id, updated_schedule)
    updated_describe = Temporal.describe_schedule(namespace, schedule_id)
    expect(updated_describe.schedule.spec.jitter.seconds).to(eq(500))
    expect(updated_describe.schedule.policies.overlap_policy).to(eq(:SCHEDULE_OVERLAP_POLICY_BUFFER_ALL))
    expect(updated_describe.schedule.state.notes).to(eq("Updated by integration test"))
  end

  it "does not update if conflict token doesnt match" do
    namespace = integration_spec_namespace
    schedule_id = SecureRandom.uuid

    initial_response = Temporal.create_schedule(namespace, schedule_id, example_schedule)

    # Update the schedule but pass the incorrect token
    Temporal.update_schedule(namespace, schedule_id, updated_schedule, conflict_token: "invalid token")

    # The schedule should not have been updated (we don't get an error message from the server in this case)
    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.spec.jitter.seconds).to(eq(30))

    # If we pass the right conflict token the update should be applied
    Temporal.update_schedule(namespace, schedule_id, updated_schedule, conflict_token: initial_response.conflict_token)
    updated_describe = Temporal.describe_schedule(namespace, schedule_id)
    expect(updated_describe.schedule.spec.jitter.seconds).to(eq(500))
  end

  it "raises a NotFoundFailure if a schedule doesn't exist" do
    namespace = integration_spec_namespace

    expect do
      Temporal.update_schedule(namespace, "some-invalid-schedule-id", updated_schedule)
    end
      .to(raise_error(Temporal::NotFoundFailure))
  end
end
