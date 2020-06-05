require 'temporal/workflow'
require 'temporal/thread_local_context'

describe Temporal::Workflow::ConvenienceMethods do
  class TestWorkflow < Temporal::Workflow; end

  subject { TestWorkflow }

  let(:context) { instance_double('Temporal::Workflow::Context') }
  let(:input) { 'input' }
  let(:options) { { param_1: true } }

  after { Temporal::ThreadLocalContext.set(nil) }

  describe '.execute' do
    context 'with local context' do
      before do
        Temporal::ThreadLocalContext.set(context)
        allow(context).to receive(:execute_workflow)
      end

      it 'executes activity' do
        subject.execute(input, options)

        expect(context)
          .to have_received(:execute_workflow)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Temporal::ThreadLocalContext.set(nil) }

      it 'raises an error' do
        expect do
          subject.execute
        end.to raise_error('Called Workflow#execute outside of a Workflow context')
      end
    end
  end

  describe '.execute!' do
    context 'with local context' do
      before do
        Temporal::ThreadLocalContext.set(context)
        allow(context).to receive(:execute_workflow!)
      end

      it 'executes activity' do
        subject.execute!(input, options)

        expect(context)
          .to have_received(:execute_workflow!)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Temporal::ThreadLocalContext.set(nil) }

      it 'raises an error' do
        expect do
          subject.execute!(input, options)
        end.to raise_error('Called Workflow#execute! outside of a Workflow context')
      end
    end
  end
end
