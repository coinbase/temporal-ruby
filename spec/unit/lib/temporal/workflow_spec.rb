require 'temporal/workflow'
require 'temporal/workflow/context'
require 'shared_examples/an_executable'

describe Temporal::Workflow do
  it_behaves_like 'an executable'

  class ArgsWorkflow < Temporal::Workflow
    def execute(a)
      'args result'
    end
  end

  class KwargsWorkflow < Temporal::Workflow
    def execute(a, b:, c:)
      'kwargs result'
    end
  end

  subject { described_class.new(ctx) }
  let(:ctx) { instance_double('Temporal::Workflow::Context') }

  before do
    allow(ctx).to receive(:completed?).and_return(true)
  end

  describe '.execute_in_context' do
    subject { ArgsWorkflow.new(ctx) }

    let(:input) { ['test'] }

    before do
      allow(described_class).to receive(:new).and_return(subject)
    end

    it 'passes the context' do
      described_class.execute_in_context(ctx, input)

      expect(described_class).to have_received(:new).with(ctx)
    end

    it 'calls #execute' do
      expect(subject).to receive(:execute).with(*input)

      described_class.execute_in_context(ctx, input)
    end

    context 'when using keyword arguments' do
      subject { KwargsWorkflow.new(ctx) }

      let(:input) { ['test', { b: 'b', c: 'c' }] }

      it 'passes the context' do
        described_class.execute_in_context(ctx, input)

        expect(described_class).to have_received(:new).with(ctx)
      end

      it 'calls #execute' do
        expect(subject).to receive(:execute).with('test', b: 'b', c: 'c')

        described_class.execute_in_context(ctx, input)
      end

      it 'does not raise an ArgumentError' do
        expect {
          described_class.execute_in_context(ctx, input)
        }.not_to raise_error
      end
    end
  end

  describe '#execute' do
    it 'is not implemented on a superclass' do
      expect { subject.execute }.to raise_error(NotImplementedError)
    end
  end
end
