require "workflows/signal_with_start_workflow"
require "temporal/testing/replay_tester"
require "temporal/workflow/history/serialization"

describe "signal with start with ignored event" do
  let(:replay_tester) { Temporal::Testing::ReplayTester.new }

  it "replays successfully with a WORKFLOW_EXECUTION_OPTIONS_UPDATED event in the history" do
    replay_tester.replay_history(
      SignalWithStartWorkflow,
      Temporal::Workflow::History::Serialization.from_json_file("spec/replay/histories/signal_with_start_ignored_event.json")
    )
  end
end
