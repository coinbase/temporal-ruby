require 'workflows/local_hello_world_workflow'

describe LocalHelloWorldWorkflow do
  subject { described_class }

  before do
    allow(HelloWorldActivity).to receive(:execute!).and_call_original
    allow(HelloWorldActivity).to receive(:execute_locally).and_call_original
  end

  it 'executes HelloWorldActivity twice' do
    subject.execute_locally

    expect(HelloWorldActivity).to have_received(:execute_locally).with('Alice').ordered
    expect(HelloWorldActivity).to have_received(:execute!).with('Bob').ordered
  end

  it 'returns nil' do
    expect(subject.execute_locally).to eq(nil)
  end
end
