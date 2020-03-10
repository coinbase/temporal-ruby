require 'workflows/branching_workflow'

describe BranchingWorkflow do
  subject { described_class }

  before do
    allow_any_instance_of(RandomNumberActivity)
      .to receive(:rand)
      .with(0..100)
      .and_return(random_number)
  end

  context 'when random number is below 50' do
    let(:random_number) { 42 }

    it 'executes HelloWorldActivity' do
      expect_any_instance_of(HelloWorldActivity)
        .to receive(:execute)
        .with('bottom half')
        .and_call_original

      subject.execute_locally
    end

    it 'returns a picked number' do
      expect(subject.execute_locally).to eq("Number picked was: #{random_number}")
    end
  end

  context 'when random number is above 50' do
    let(:random_number) { 84 }

    it 'executes HelloWorldActivity' do
      expect_any_instance_of(HelloWorldActivity)
        .to receive(:execute)
        .with('top half')
        .and_call_original

      subject.execute_locally
    end

    it 'returns a picked number' do
      expect(subject.execute_locally).to eq("Number picked was: #{random_number}")
    end
  end
end
