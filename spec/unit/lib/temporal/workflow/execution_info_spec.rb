require 'temporal/workflow/execution_info'

describe Temporal::Workflow::ExecutionInfo do
  subject { described_class.generate_from(api_info) }
  let(:api_info) { Fabricate(:api_workflow_execution_info, workflow: 'TestWorkflow', workflow_id: '') }

  describe '.generate_for' do

    it 'generates info from api' do
      expect(subject.workflow).to eq(api_info.type.name)
      expect(subject.workflow_id).to eq(api_info.execution.workflow_id)
      expect(subject.run_id).to eq(api_info.execution.run_id)
      expect(subject.start_time).to be_a(Time)
      expect(subject.close_time).to be_a(Time)
      expect(subject.status).to eq(:COMPLETED)
      expect(subject.history_length).to eq(api_info.history_length)
      expect(subject.memo).to eq({ 'foo' => 'bar' })
      expect(subject.search_attributes).to eq({ 'foo' => 'bar' })
    end

    it 'freezes the info' do
      expect(subject).to be_frozen
    end

    it 'deserializes if search_attributes is nil' do
      api_info.search_attributes = nil

      result = described_class.generate_from(api_info)
      expect(result.search_attributes).to eq({})
    end
  end

  describe 'statuses' do
    let(:api_info) do
      Fabricate(
        :api_workflow_execution_info,
        workflow: 'TestWorkflow',
        workflow_id: '',
        status: Temporalio::Api::Enums::V1::WorkflowExecutionStatus::WORKFLOW_EXECUTION_STATUS_TERMINATED
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

  describe '#closed?' do
    Temporal::Workflow::Status::API_STATUS_MAP.keys.select { |x| x != :WORKFLOW_EXECUTION_STATUS_RUNNING }.each do |status|
      context "when status is #{status}" do
          let(:api_info) do
            Fabricate(
              :api_workflow_execution_info,
              workflow: 'TestWorkflow',
              workflow_id: '',
              status: Temporalio::Api::Enums::V1::WorkflowExecutionStatus.resolve(status)
            )
          end
          it { is_expected.to be_closed }
        end
      end

    context "when status is RUNNING" do
      let(:api_info) do
        Fabricate(
          :api_workflow_execution_info,
          workflow: 'TestWorkflow',
          workflow_id: '',
          status: Temporalio::Api::Enums::V1::WorkflowExecutionStatus.resolve(:WORKFLOW_EXECUTION_STATUS_RUNNING)
        )
      end

      it { is_expected.not_to be_closed }
    end
  end
end
