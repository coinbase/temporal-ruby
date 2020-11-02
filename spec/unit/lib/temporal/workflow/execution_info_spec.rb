require 'temporal/workflow/execution_info'

describe Temporal::Workflow::ExecutionInfo do
  subject { described_class.generate_from(api_info) }
  let(:api_info) { Fabricate(:api_workflow_execution_info) }

  describe '.generate_for' do

    it 'generates info from api' do
      expect(subject.workflow).to eq(api_info.type.name)
      expect(subject.workflow_id).to eq(api_info.execution.workflow_id)
      expect(subject.run_id).to eq(api_info.execution.run_id)
      expect(subject.start_time).to be_a(Time)
      expect(subject.close_time).to be_a(Time)
      expect(subject.status).to eq(:COMPLETED)
      expect(subject.history_length).to eq(api_info.history_length)
    end

    it 'freezes the info' do
      expect(subject).to be_frozen
    end
  end

  describe 'statuses' do
    let(:api_info) do
      Fabricate(
        :api_workflow_execution_info,
        status: Temporal::Api::Enums::V1::WorkflowExecutionStatus::WORKFLOW_EXECUTION_STATUS_TERMINATED
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
