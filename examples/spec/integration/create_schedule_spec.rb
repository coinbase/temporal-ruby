require "temporal/errors"
require "temporal/schedule/backfill"
require "temporal/schedule/calendar"
require "temporal/schedule/interval"
require "temporal/schedule/schedule"
require "temporal/schedule/schedule_spec"
require "temporal/schedule/schedule_policies"
require "temporal/schedule/schedule_state"
require "temporal/schedule/start_workflow_action"

describe "Temporal.create_schedule", :integration do
  let(:example_schedule) do
    workflow_id = SecureRandom.uuid
    Temporal::Schedule::Schedule.new(
      spec: Temporal::Schedule::ScheduleSpec.new(
        calendars: [Temporal::Schedule::Calendar.new(day_of_week: "*", hour: "18", minute: "30")],
        intervals: [Temporal::Schedule::Interval.new(every: 6000, offset: 300)],
        cron_expressions: ["@hourly"],
        jitter: 30,
        # Set an end time so that the test schedule doesn't run forever
        end_time: Time.now + 600
      ),
      action: Temporal::Schedule::StartWorkflowAction.new(
        "HelloWorldWorkflow",
        "Test",
        options: {
          workflow_id: workflow_id,
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

  it "can create schedules" do
    namespace = integration_spec_namespace

    schedule_id = SecureRandom.uuid

    create_response = Temporal.create_schedule(
      namespace,
      schedule_id,
      example_schedule,
      memo: {"schedule_memo" => "schedule memo value"},
      trigger_immediately: true,
      backfill: Temporal::Schedule::Backfill.new(start_time: (Date.today - 90).to_time, end_time: Time.now)
    )
    expect(create_response).to(be_an_instance_of(Temporalio::Api::WorkflowService::V1::CreateScheduleResponse))

    describe_response = Temporal.describe_schedule(namespace, schedule_id)

    expect(describe_response.memo).to(eq({"schedule_memo" => "schedule memo value"}))
    expect(describe_response.schedule.spec.jitter.seconds).to(eq(30))
    expect(describe_response.schedule.policies.overlap_policy).to(eq(:SCHEDULE_OVERLAP_POLICY_BUFFER_ONE))
    expect(describe_response.schedule.action.start_workflow.workflow_type.name).to(eq("HelloWorldWorkflow"))
    expect(describe_response.schedule.state.notes).to(eq("Created by integration test"))
  end

  it "can create schedules with a minimal set of fields" do
    namespace = integration_spec_namespace
    schedule_id = SecureRandom.uuid

    schedule = Temporal::Schedule::Schedule.new(
      spec: Temporal::Schedule::ScheduleSpec.new(
        cron_expressions: ["@hourly"],
        # Set an end time so that the test schedule doesn't run forever
        end_time: Time.now + 600
      ),
      action: Temporal::Schedule::StartWorkflowAction.new(
        "HelloWorldWorkflow",
        "Test",
        options: {task_queue: Temporal.configuration.task_queue}
      )
    )

    Temporal.create_schedule(namespace, schedule_id, schedule)

    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.schedule.action.start_workflow.workflow_type.name).to(eq("HelloWorldWorkflow"))
    expect(describe_response.schedule.policies.overlap_policy).to(eq(:SCHEDULE_OVERLAP_POLICY_SKIP))
  end
end
