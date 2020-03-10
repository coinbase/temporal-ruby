require 'workflows/serial_hello_world_workflow'

describe SerialHelloWorldWorkflow do
  subject { described_class }

  before { allow(HelloWorldActivity).to receive(:execute!).and_call_original }

  it 'executes HelloWorldActivity' do
    subject.execute_locally('Alice', 'Bob', 'John')

    expect(HelloWorldActivity).to have_received(:execute!).with('Alice').ordered
    expect(HelloWorldActivity).to have_received(:execute!).with('Bob').ordered
    expect(HelloWorldActivity).to have_received(:execute!).with('John').ordered
  end

  it 'returns nil' do
    expect(subject.execute_locally).to eq(nil)
  end
end
