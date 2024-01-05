require "timeout"
require "temporal/errors"
require "temporal/schedule/backfill"
require "temporal/schedule/calendar"
require "temporal/schedule/interval"
require "temporal/schedule/schedule"
require "temporal/schedule/schedule_spec"
require "temporal/schedule/schedule_policies"
require "temporal/schedule/schedule_state"
require "temporal/schedule/start_workflow_action"

describe "Temporal.list_schedules", :integration do
  let(:example_schedule) do
    workflow_id = SecureRandom.uuid
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

  def cleanup
    namespace = integration_spec_namespace
    loop do
      resp = Temporal.list_schedules(namespace, maximum_page_size: 1000)
      resp.schedules.each do |schedule|
        begin
          Temporal.delete_schedule(namespace, schedule.schedule_id)
        rescue Temporal::NotFoundFailure
          # This sometimes throws if a schedule has already been 'completed' (end time is reached)
        end
      end
      break if resp.next_page_token == ""
    end
  end

  before do
    cleanup
  end


  it "can list schedules with pagination" do
    namespace = integration_spec_namespace

    10.times do
      schedule_id = SecureRandom.uuid
      Temporal.create_schedule(namespace, schedule_id, example_schedule)
    end

    # list_schedules is eventually consistent. Wait until at least 10 schedules are returned
    Timeout.timeout(10) do
      loop do
        result = Temporal.list_schedules(namespace, maximum_page_size: 100)

        break if result && result.schedules.count >= 10

        sleep(0.5)
      end
    end

    page_one = Temporal.list_schedules(namespace, maximum_page_size: 2)
    expect(page_one.schedules.count).to(eq(2))
    page_two = Temporal.list_schedules(namespace, next_page_token: page_one.next_page_token, maximum_page_size: 8)
    expect(page_two.schedules.count).to(eq(8))

    # ensure that we got dfifereent schedules in each page
    page_two_schedule_ids = page_two.schedules.map(&:schedule_id)
    page_one.schedules.each do |schedule|
      expect(page_two_schedule_ids).not_to(include(schedule.schedule_id))
    end
  end

  it "roundtrip encodes/decodes memo with payload" do
    namespace = integration_spec_namespace
    schedule_id = "schedule_with_encoded_memo_payload-#{SecureRandom.uuid}}"
    Temporal.create_schedule(
      namespace,
      schedule_id,
      example_schedule,
      memo: {"schedule_memo" => "schedule memo value"}
    )

    resp = nil
    matching_schedule = nil

    # list_schedules is eventually consistent. Wait until our created schedule is returned
    Timeout.timeout(10) do
      loop do
        resp = Temporal.list_schedules(namespace, maximum_page_size: 1000)

        matching_schedule = resp.schedules.find { |s| s.schedule_id == schedule_id }
        break unless matching_schedule.nil?

        sleep(0.1)
      end
    end

    expect(matching_schedule.memo).to(eq({"schedule_memo" => "schedule memo value"}))
  end
end
