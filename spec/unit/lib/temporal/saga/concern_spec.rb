require 'temporal/saga/concern'

describe Temporal::Saga::Concern do
  class TestSagaConcernActivity1 < Temporal::Activity; end
  class TestSagaConcernActivity2 < Temporal::Activity; end
  class TestSagaConcernActivity3 < Temporal::Activity; end

  class TestSagaConcernWorkflow < Temporal::Workflow
    include Temporal::Saga::Concern

    def execute
      result = run_saga do |saga|
        TestSagaConcernActivity1.execute!
        saga.add_compensation(TestSagaConcernActivity2, 42)
        TestSagaConcernActivity3.execute!
      end

      return result
    end
  end

  subject { TestSagaConcernWorkflow.new(context) }
  let(:context) { instance_double('Temporal::Workflow::Context') }

  before do
    allow(context).to receive(:execute_activity!)
    allow(TestSagaConcernActivity1).to receive(:execute!)
    allow(TestSagaConcernActivity3).to receive(:execute!)
  end

  context 'when execution completes' do
    it 'runs the provided block' do
      subject.execute

      expect(TestSagaConcernActivity1).to have_received(:execute!).ordered
      expect(TestSagaConcernActivity3).to have_received(:execute!).ordered
      expect(context).not_to have_received(:execute_activity!).with(TestSagaConcernActivity2, 42)
    end

    it 'returns completed result' do
      result = subject.execute

      expect(result).to be_instance_of(Temporal::Saga::Result)
      expect(result).to be_completed
    end
  end

  context 'when execution compensates' do
    let(:logger) { instance_double('Temporal::Logger') }
    let(:error) { TestSagaConcernError.new('execution failed') }

    class TestSagaConcernError < StandardError
      def backtrace
        ['line 1', 'line 2']
      end
    end

    before do
      allow(TestSagaConcernActivity3).to receive(:execute!).and_raise(error)
      allow(context).to receive(:logger).and_return(logger)
      allow(logger).to receive(:error)
      allow(logger).to receive(:debug)
    end

    it 'performs compensation' do
      subject.execute

      expect(TestSagaConcernActivity1).to have_received(:execute!).ordered
      expect(TestSagaConcernActivity3).to have_received(:execute!).ordered
      expect(context)
        .to have_received(:execute_activity!)
        .with(TestSagaConcernActivity2, 42).ordered
    end

    it 'returns compensated result' do
      result = subject.execute

      expect(result).to be_instance_of(Temporal::Saga::Result)
      expect(result).to be_compensated
      expect(result.rollback_reason).to eq(error)
    end

    it 'logs' do
      subject.execute

      expect(logger)
        .to have_received(:error)
        .with('Saga execution aborted', { error: '#<TestSagaConcernError: execution failed>' })
      expect(logger).to have_received(:debug).with("line 1\nline 2")
    end
  end
end
