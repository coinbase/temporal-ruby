require 'cadence/activity'
require 'shared_examples/an_executable'

describe Cadence::Activity do
  it_behaves_like 'an executable'

  subject { described_class.new(context) }
  let(:context) { instance_double('Cadence::Activity::Context') }

  describe '.execute_in_context' do
    let(:input) { ['test'] }

    before do
      allow(described_class).to receive(:new).and_return(subject)
      allow(subject).to receive(:execute).and_return('result')
    end

    it 'passes the context' do
      described_class.execute_in_context(context, input)

      expect(described_class).to have_received(:new).with(context)
    end

    it 'calls #execute' do
      described_class.execute_in_context(context, input)

      expect(subject).to have_received(:execute).with(*input)
    end

    it 'returns #execute result' do
      expect(described_class.execute_in_context(context, input)).to eq('result')
    end
  end

  describe '#execute' do
    it 'is not implemented on a superclass' do
      expect { subject.execute }.to raise_error(NotImplementedError)
    end
  end

  describe '#activity' do
    it 'exposes context to its subclasses' do
      expect(subject.send(:activity)).to eq(context)
    end
  end
end
