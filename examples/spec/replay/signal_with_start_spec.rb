require 'workflows/signal_with_start_workflow'
require 'temporal/testing/replay_tester'

describe 'signal with start' do
  let(:replay_tester) { Temporal::Testing::ReplayTester.new }

  it 'two misses, one hit, replay, json' do
    replay_tester.replay_history_json_file(SignalWithStartWorkflow, 'spec/replay/histories/signal_with_start.json')
  end

  it 'two misses, one hit, replay, binary' do
    replay_tester.replay_history_protobuf_file(
      SignalWithStartWorkflow,
      'spec/replay/histories/signal_with_start.binpb'
    )
  end
end
