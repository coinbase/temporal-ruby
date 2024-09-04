require "timeout"
require "temporal/schedule/schedule"
require "temporal/schedule/calendar"
require "temporal/schedule/schedule_spec"
require "temporal/schedule/schedule_policies"
require "temporal/schedule/schedule_state"
require "temporal/schedule/start_workflow_action"

describe "Temporal.trigger_schedule", :integration do
  let(:example_schedule) do
    Temporal::Schedule::Schedule.new(
      spec: Temporal::Schedule::ScheduleSpec.new(
        # Set this to a date in the future to avoid triggering the schedule immediately
        calendars: [Temporal::Schedule::Calendar.new(year: "2055", month: "12", day_of_month: "25")]
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

  it "can trigger a schedule to run immediately" do
    namespace = integration_spec_namespace
    schedule_id = SecureRandom.uuid

    Temporal.create_schedule(namespace, schedule_id, example_schedule)
    describe_response = Temporal.describe_schedule(namespace, schedule_id)
    expect(describe_response.info.recent_actions.size).to(eq(0))

    # Trigger the schedule and wait to see that it actually ran
    Temporal.trigger_schedule(namespace, schedule_id, overlap_policy: :buffer_one)

    Timeout.timeout(10) do
      loop do
        describe_response = Temporal.describe_schedule(namespace, schedule_id)

        break if describe_response.info && describe_response.info.recent_actions.size >= 1

        sleep(0.5)
      end
    end

    expect(describe_response.info.recent_actions.size).to(eq(1))
  end
end
