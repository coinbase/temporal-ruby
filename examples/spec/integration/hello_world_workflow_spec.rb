require 'workflows/hello_world_workflow'

describe HelloWorldWorkflow do
  subject { described_class }

  before { allow(HelloWorldActivity).to receive(:execute!).and_call_original }

  it 'executes HelloWorldActivity' do
    subject.execute_locally

    expect(HelloWorldActivity).to have_received(:execute!).with('Alice')
  end

  it 'returns text' do
    expect(subject.execute_locally).to eq("Hello World, Alice")
  end
end
