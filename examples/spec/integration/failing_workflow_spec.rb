require 'workflows/failing_workflow'

describe FailingWorkflow do
  subject { described_class }

  before do
    allow_any_instance_of(RandomlyFailingActivity)
      .to receive(:rand)
      .with(6)
      .and_return(random_number)
  end

  context 'when random number is 0' do
    let(:random_number) { 0 }

    it 'raises' do
      expect do
        subject.execute_locally
      end.to raise_error(RandomlyFailingActivity::TerminalGuess, 'You are the unluckiest!')
    end
  end

  context 'when random number is 2' do
    let(:random_number) { 2 }

    it 'returns result' do
      expect(subject.execute_locally).to eq('You are very lucky!')
    end
  end

  context 'when random number neither 0 nor 2' do
    let(:random_number) { 4 }

    it 'returns result' do
      expect(subject.execute_locally).to eq('Better luck next time')
    end
  end
end
