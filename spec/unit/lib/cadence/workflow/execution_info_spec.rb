require 'cadence/workflow/execution_info'

describe Cadence::Workflow::ExecutionInfo do
  subject { described_class.generate_from(thrift) }
  let(:thrift) { Fabricate(:workflow_execution_info_thrift) }

  describe '.generate_for' do

    it 'generates info from thrift' do
      expect(subject.workflow).to eq(thrift.type.name)
      expect(subject.workflow_id).to eq(thrift.execution.workflowId)
      expect(subject.run_id).to eq(thrift.execution.runId)
      expect(subject.start_time).to be_a(Time)
      expect(subject.close_time).to be_a(Time)
      expect(subject.status).to eq(:COMPLETED)
      expect(subject.history_length).to eq(thrift.historyLength)
    end

    it 'freezes the info' do
      expect(subject).to be_frozen
    end
  end

  describe 'statuses' do
    let(:thrift) do
      Fabricate(
        :workflow_execution_info_thrift,
        closeStatus: CadenceThrift::WorkflowExecutionCloseStatus::TERMINATED
      )
    end

    it 'has status methods' do
      expect(subject).to respond_to(:running?)
      expect(subject).to respond_to(:completed?)
      expect(subject).to respond_to(:failed?)
      expect(subject).to respond_to(:canceled?)
      expect(subject).to respond_to(:terminated?)
      expect(subject).to respond_to(:continued_as_new?)
      expect(subject).to respond_to(:timed_out?)
    end

    it 'responds correctly to status queries' do
      expect(subject).to be_terminated

      expect(subject).not_to be_running
      expect(subject).not_to be_completed
      expect(subject).not_to be_failed
      expect(subject).not_to be_canceled
      expect(subject).not_to be_continued_as_new
      expect(subject).not_to be_timed_out
    end
  end
end
