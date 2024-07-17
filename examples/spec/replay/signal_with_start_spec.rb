require "workflows/signal_with_start_workflow"
require "temporal/testing/replay_tester"
require "temporal/workflow/history/serialization"

describe "signal with start" do
  let(:replay_tester) { Temporal::Testing::ReplayTester.new }

  it "two misses, one hit, replay, json" do
    replay_tester.replay_history(
      SignalWithStartWorkflow,
      Temporal::Workflow::History::Serialization.from_json_file("spec/replay/histories/signal_with_start.json")
    )
  end

  it "two misses, one hit, replay, binary" do
    replay_tester.replay_history(
      SignalWithStartWorkflow,
      Temporal::Workflow::History::Serialization.from_protobuf_file("spec/replay/histories/signal_with_start.binpb")
    )
  end
end
