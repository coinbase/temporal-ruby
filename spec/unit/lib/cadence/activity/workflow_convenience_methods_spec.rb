require 'cadence/activity'

describe Cadence::Activity::WorkflowConvenienceMethods do
  class TestActivity < Cadence::Activity; end

  subject { TestActivity }

  let(:context) { instance_double('Cadence::Workflow::Context') }
  let(:input) { 'input' }
  let(:options) { { param_1: true } }

  describe '.execute' do
    context 'with local context' do
      before do
        Thread.current[:local_workflow_context] = context
        allow(context).to receive(:execute_activity)
      end

      it 'executes activity' do
        subject.execute(input, options)

        expect(context)
          .to have_received(:execute_activity)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Thread.current[:local_workflow_context] = nil }

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
        Thread.current[:local_workflow_context] = context
        allow(context).to receive(:execute_activity!)
      end

      it 'executes activity' do
        subject.execute!(input, options)

        expect(context)
          .to have_received(:execute_activity!)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Thread.current[:local_workflow_context] = nil }

      it 'raises an error' do
        expect do
          subject.execute!(input, options)
        end.to raise_error('Called Activity#execute! outside of a Workflow context')
      end
    end
  end

  describe '.execute_locally' do
    context 'with local context' do
      before do
        Thread.current[:local_workflow_context] = context
        allow(context).to receive(:execute_local_activity)
      end

      it 'executes activity' do
        subject.execute_locally(input, options)

        expect(context)
          .to have_received(:execute_local_activity)
          .with(subject, input, options)
      end
    end

    context 'without local context' do
      before { Thread.current[:local_workflow_context] = nil }

      it 'raises an error' do
        expect do
          subject.execute_locally(input, options)
        end.to raise_error('Called Activity#execute_locally outside of a Workflow context')
      end
    end
  end
end
