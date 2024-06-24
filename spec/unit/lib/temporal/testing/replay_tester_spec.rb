require "base64"
require "json"
require "temporal/testing/replay_tester"
require "temporal/workflow"
require "temporal/workflow/history"

describe Temporal::Testing::ReplayTester do
  class TestReplayActivity < Temporal::Activity
    def execute
      raise "should never run"
    end
  end

  class TestReplayWorkflow < Temporal::Workflow
    def execute(run_activity: false, run_sleep: false, result: "success")
      TestReplayActivity.execute! if run_activity

      workflow.sleep(1) if run_sleep

      case result
      when "success"
        "done"
      when "continue_as_new"
        workflow.continue_as_new
        nil
      when "await"
        # wait forever
        workflow.wait_until { false }
      when "fail"
        raise "failed"
      end
    end
  end

  let(:replay_tester) { Temporal::Testing::ReplayTester.new }
  let(:do_nothing_json) do
    File.read(
      "spec/unit/lib/temporal/testing/replay_histories/do_nothing.json"
    )
  end

  let(:do_nothing) do
    Temporal::Workflow::History::Serialization.from_json(do_nothing_json)
  end

  it "replay do nothing successful" do
    replay_tester.replay_history(
      TestReplayWorkflow,
      do_nothing
    )
  end

  def remove_first_history_event(history)
    history.events.shift
    history
  end

  it "replay missing start workflow execution event" do
    replay_tester.replay_history(
      TestReplayWorkflow,
      remove_first_history_event(do_nothing)
    )
    raise "Expected error to raise"
  rescue Temporal::Testing::ReplayError => e
    expect(e.message).to(eq("History does not start with workflow_execution_started event"))
  end

  def set_workflow_args_in_history(json_args)
    obj = JSON.load(do_nothing_json)
    obj["events"][0]["workflowExecutionStartedEventAttributes"]["input"]["payloads"][0]["data"] = Base64.strict_encode64(
      json_args
    )
    new_json = JSON.generate(obj)
    Temporal::Workflow::History::Serialization.from_json(new_json)
  end

  it "replay extra activity" do
    # The linked history will cause an error because it will cause an activity run even though
    # there isn't one in the history.

    replay_tester.replay_history(
      TestReplayWorkflow,
      set_workflow_args_in_history("{\":run_activity\":true}")
    )
    raise "Expected error to raise"
  rescue Temporal::Testing::ReplayError => e
    expect(e.message).to(eq("Workflow code failed to replay successfully against history"))
    # Ensure backtrace was overwritten
    expect(e.backtrace.first).to(start_with("Fiber backtraces:"))
    expect(e.cause).to(be_a(Temporal::NonDeterministicWorkflowError))
    expect(e.cause.message).to(
      eq(
        "Unexpected command. The replaying code is issuing: activity (5), but the history of previous executions " \
          "recorded: complete_workflow (5). Likely, either you have made a version-unsafe change to your workflow or " \
          "have non-deterministic behavior in your workflow. See https://docs.temporal.io/docs/java/versioning/#introduction-to-versioning."
      )
    )
  end

  it "replay continues as new when history completed" do
    # The linked history will cause an error because it will cause the workflow to continue
    # as new on replay when in the history, it completed successfully.

    replay_tester.replay_history(
      TestReplayWorkflow,
      set_workflow_args_in_history("{\":result\":\"continue_as_new\"}")
    )
    raise "Expected error to raise"
  rescue Temporal::Testing::ReplayError => e
    expect(e.message).to(eq("Workflow code failed to replay successfully against history"))
    expect(e.cause).to(be_a(Temporal::NonDeterministicWorkflowError))
    expect(e.cause.message).to(
      eq(
        "Unexpected command. The replaying code is issuing: continue_as_new_workflow (5), but the history of " \
          "previous executions recorded: complete_workflow (5). Likely, either you have made a version-unsafe " \
          "change to your workflow or have non-deterministic behavior in your workflow. " \
          "See https://docs.temporal.io/docs/java/versioning/#introduction-to-versioning."
      )
    )
  end

  it "replay keeps going when history succeeded" do
    # The linked history will cause an error because it will cause the workflow to keep running
    # when in the history, it completed successfully.

    replay_tester.replay_history(
      TestReplayWorkflow,
      set_workflow_args_in_history("{\":result\":\"await\"}")
    )
    raise "Expected error to raise"
  rescue Temporal::Testing::ReplayError => e
    expect(e.message).to(eq("Workflow code failed to replay successfully against history"))
    expect(e.cause).to(be_a(Temporal::NonDeterministicWorkflowError))
    expect(e.cause.message).to(
      eq(
        "A command in the history of previous executions, complete_workflow (5), was not scheduled upon replay. " \
          "Likely, either you have made a version-unsafe change to your workflow or have non-deterministic behavior " \
          "in your workflow. See https://docs.temporal.io/docs/java/versioning/#introduction-to-versioning."
      )
    )
  end
end
