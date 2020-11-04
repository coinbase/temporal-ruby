require 'temporal/activity'
require 'temporal/thread_local_context'

describe Temporal::Activity::WorkflowConvenienceMethods do
  class TestActivity < Temporal::Activity; end

  subject { TestActivity }

  let(:context) { instance_double('Temporal::Workflow::Context') }
  let(:input) { 'input' }
  let(:options) { { param_1: true } }

  after { Temporal::ThreadLocalContext.set(nil) }

  describe '.execute' do
    context 'with local context' do
      before do
        Temporal::ThreadLocalContext.set(context)
        allow(context).to receive(:execute_activity)
      end

      it 'executes activity' do
        subject.execute(input, **options)

        expect(context)
          .to have_received(:execute_activity)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Temporal::ThreadLocalContext.set(nil) }

      it 'raises an error' do
        expect do
          subject.execute
        end.to raise_error('Called Activity#execute outside of a Workflow context')
      end
    end
  end

  describe '.execute!' do
    context 'with local context' do
      before do
        Temporal::ThreadLocalContext.set(context)
        allow(context).to receive(:execute_activity!)
      end

      it 'executes activity' do
        subject.execute!(input, **options)

        expect(context)
          .to have_received(:execute_activity!)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Temporal::ThreadLocalContext.set(nil) }

      it 'raises an error' do
        expect do
          subject.execute!(input, **options)
        end.to raise_error('Called Activity#execute! outside of a Workflow context')
      end
    end
  end

  describe '.execute_locally' do
    context 'with local context' do
      before do
        Temporal::ThreadLocalContext.set(context)
        allow(context).to receive(:execute_local_activity)
      end

      it 'executes activity' do
        subject.execute_locally(input, **options)

        expect(context)
          .to have_received(:execute_local_activity)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Temporal::ThreadLocalContext.set(nil) }

      it 'raises an error' do
        expect do
          subject.execute_locally(input, **options)
        end.to raise_error('Called Activity#execute_locally outside of a Workflow context')
      end
    end
  end
end
