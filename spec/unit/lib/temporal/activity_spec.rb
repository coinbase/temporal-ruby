require 'temporal/activity'
require 'shared_examples/an_executable'

describe Temporal::Activity do
  it_behaves_like 'an executable'

  class ArgsActivity < Temporal::Activity
    def execute(a)
      'args result'
    end
  end

  class KwargsActivity < Temporal::Activity
    def execute(a, b:, c:)
      'kwargs result'
    end
  end

  subject { described_class.new(context) }
  let(:context) { instance_double('Temporal::Activity::Context') }

  describe '.execute_in_context' do
    subject { ArgsActivity.new(context) }

    let(:input) { ['test'] }

    before do
      allow(described_class).to receive(:new).and_return(subject)
    end

    it 'passes the context' do
      described_class.execute_in_context(context, input)

      expect(described_class).to have_received(:new).with(context)
    end

    it 'calls #execute' do
      expect(subject).to receive(:execute).with(*input)

      described_class.execute_in_context(context, input)
    end

    it 'returns #execute result' do
      expect(described_class.execute_in_context(context, input)).to eq('args result')
    end

    context 'when using keyword arguments' do
      subject { KwargsActivity.new(context) }

      let(:input) { ['test', { b: 'b', c: 'c' }] }

      it 'passes the context' do
        described_class.execute_in_context(context, input)

        expect(described_class).to have_received(:new).with(context)
      end

      it 'calls #execute' do
        expect(subject).to receive(:execute).with('test', b: 'b', c: 'c')

        described_class.execute_in_context(context, input)
      end

      it 'does not raise an ArgumentError' do
        expect {
          described_class.execute_in_context(context, input)
        }.not_to raise_error
      end

      it 'returns #execute result' do
        expect(described_class.execute_in_context(context, input)).to eq('kwargs result')
      end
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
