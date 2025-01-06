# frozen_string_literal: true

require 'temporal/worker'
require 'temporal/testing/connection'
require 'temporal/testing/client'
require_relative './timeskippable_workflow'
require 'timeout'
describe 'Timeskipping' do
  before :all do
    Thread.abort_on_exception = true
    Temporal.configure do |config|
      config.host = 'localhost'
      config.port = 7233
      config.namespace = 'default'
      config.task_queue = 'default'
    end

    @worker = Temporal::Worker.new
    @worker.register_workflow TimeskippableWorkflow
    @worker_thread = Thread.new do
      @worker.start
    end
  end
  after :all do
    @worker.stop
    @worker_thread.kill.join
  end
  it 'should connect to timeskipping server' do

    workflow_id = SecureRandom.uuid
    conn = Temporal::Testing::Connection.new("localhost", 7233)
    run_id = Temporal.start_workflow(
      TimeskippableWorkflow,
      25_000_000, # it continues as new if this arg is > 1
      options: {
        workflow_id: workflow_id,
        task_queue: Temporal.configuration.task_queue,
      },
    )
    conn.unlock_time_skipping_with_sleep(20_000_000)
    Temporal.signal_workflow(TimeskippableWorkflow, 'unblock', workflow_id, run_id)
    begin
      sleep(0.5)

      conn.unlock_time_skipping

      result = Temporal.await_workflow_result(
        TimeskippableWorkflow,
        workflow_id: workflow_id,
      )
    ensure
      conn.lock_time_skipping
    end
    p "result: #{result}"
    expect(result).not_to be_nil
    # end
  end
  it 'should use testing client' do

    workflow_id = SecureRandom.uuid
    # extract the config from the default Temporal client
    client = Temporal::Testing::Client.new(Temporal.send :config)
    run_id = Temporal.start_workflow(
      TimeskippableWorkflow,
      25_000_000, # it continues as new if this arg is > 1
      options: {
        workflow_id: workflow_id,
        task_queue: Temporal.configuration.task_queue,
      },
      )

    client.signal_workflow(TimeskippableWorkflow, 'unblock', workflow_id, run_id)
    result = Temporal.await_workflow_result(
      TimeskippableWorkflow,
      workflow_id: workflow_id,
      )
    p "result: #{result}"
    expect(result).not_to be_nil

  end
end

# works multiple times when
# 1. start_workflow
# 2. unlock_time_skipping_with_sleep
# 3. signal workflow
# 4. sleep(2)
# 5. unlock_time_skipping
# 6. lock_time_skipping


