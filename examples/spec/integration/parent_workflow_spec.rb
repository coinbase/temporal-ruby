require 'workflows/parent_workflow'

describe ParentWorkflow do
  subject { described_class }

  before do
    allow(HelloWorldWorkflow).to receive(:execute!).and_call_original
    allow(HelloWorldActivity).to receive(:execute!).and_call_original
  end

  it 'executes HelloWorldWorkflow' do
    subject.execute_locally

    expect(HelloWorldWorkflow).to have_received(:execute!)
  end

  it 'executes HelloWorldActivity' do
    subject.execute_locally

    expect(HelloWorldActivity).to have_received(:execute!).with('Bob')
  end

  it 'returns nil' do
    expect(subject.execute_locally).to eq(nil)
  end
end
