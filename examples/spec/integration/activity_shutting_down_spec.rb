require 'securerandom'
require 'temporal/errors'
require 'temporal/worker'

class ShuttingDownActivity < Temporal::Activity
  class ShuttingDown < Temporal::ActivityException; end
  def execute
    10.times do
      begin
        activity.heartbeat_interrupted
      rescue Temporal::ActivityWorkerShuttingDown
        # This error will be reported to Temporal server for this activity. It is also
        # possible to return a success for this activity, in which case it will not be
        # retried.
        raise ShuttingDown, "worker is shutting down, shutting_down?=#{activity.shutting_down?}"
      end

      sleep 1
    end

    return
  end
end

class ShuttingDownWorkflow < Temporal::Workflow
  def execute(activity_task_queue)
    ShuttingDownActivity.execute!(
      options: {
        retry_policy: {
          max_attempts: 1,
        },
        task_queue: activity_task_queue
      })
  end
end

describe 'Activity shutdown', :integration do
  it 'stops a running activity' do
    id = SecureRandom.uuid
    activity_task_queue = "shutdown-activity-#{id}"
    workflow_task_queue = "shutdown-workflow-#{id}"

    activity_config = Temporal.configuration.dup.tap { |config| config.task_queue = activity_task_queue }
    activity_worker = Temporal::Worker.new(activity_config)
    activity_worker.register_activity(ShuttingDownActivity)

    workflow_config = Temporal.configuration.dup.tap { |config| config.task_queue = workflow_task_queue }
    workflow_worker = Temporal::Worker.new(workflow_config)
    workflow_worker.register_workflow(ShuttingDownWorkflow)

    begin
      Thread.new do
        workflow_worker.start
      end.run

      begin
        Thread.new do
          activity_worker.start
        end.run

        workflow_id, run_id = run_workflow(ShuttingDownWorkflow, activity_task_queue, options: { task_queue: workflow_task_queue })

        sleep 1
      ensure
        activity_worker.stop
      end

      expect do
        Temporal.await_workflow_result(
            ShuttingDownWorkflow,
            workflow_id: workflow_id,
            run_id: run_id,
        )
      end.to raise_error(ShuttingDownActivity::ShuttingDown, 'worker is shutting down, shutting_down?=true')
    ensure
      workflow_worker.stop
    end
  end
end
