require 'securerandom'
require 'temporal/errors'
require 'temporal/worker'

class TimeoutActivity < Temporal::Activity
  def initialize(context)
    super(context)
    @@timed_out = false
    @@exception = false
  end

  def self.saw_time_out?
    @@timed_out
  end

  def self.saw_exception?
    @@exception
  end

  def execute
    10.times do
      begin
        activity.heartbeat_interrupted
      rescue Temporal::ActivityExecutionTimedOut => e
        @@exception = true
        if activity.timed_out?
          logger.warn('Activity has timed out')
          @@timed_out = true
        end

        raise e
      end

      sleep 1
    end

    return
  end
end

class ActivityTimeoutWorkflow < Temporal::Workflow
  def execute
    TimeoutActivity.execute!(
      options: {
        retry_policy: {
          max_attempts: 1,
        },
        timeouts: {
          start_to_close: 1
        }
      })
  end
end

describe 'Activity start to close timeout', :integration do
  it 'timed_out? flag becomes true' do
    task_queue = "timeout-#{SecureRandom.uuid}"

    config = Temporal.configuration.dup.tap { |config| config.task_queue = task_queue }
    worker = Temporal::Worker.new(config)
    worker.register_activity(TimeoutActivity)
    worker.register_workflow(ActivityTimeoutWorkflow)

    begin
      Thread.new do
        worker.start
      end.run

      workflow_id, run_id = run_workflow(ActivityTimeoutWorkflow, options: { task_queue: task_queue })
      expect do
        Temporal.await_workflow_result(
            ActivityTimeoutWorkflow,
            workflow_id: workflow_id,
            run_id: run_id,
        )
      end.to raise_error(Temporal::TimeoutError, 'Timeout type: TIMEOUT_TYPE_START_TO_CLOSE')
    ensure
      worker.stop
    end

    expect(TimeoutActivity.saw_time_out?).to be(true)
    expect(TimeoutActivity.saw_exception?).to be(true)
  end
end
