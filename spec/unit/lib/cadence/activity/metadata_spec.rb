require 'cadence/activity/metadata'

describe Cadence::Activity::Metadata do
  describe '.from_task' do
    subject { described_class.from_task(task) }
    let(:task) { Fabricate(:activity_task) }

    it 'generates metadata' do
      expect(subject.id).to eq(task.activityId)
      expect(subject.task_token).to eq(task.taskToken)
      expect(subject.attempt).to eq(task.attempt)
      expect(subject.workflow_run_id).to eq(task.workflowExecution.runId)
      expect(subject.workflow_id).to eq(task.workflowExecution.workflowId)
      expect(subject.workflow_name).to eq(task.workflowType.name)
    end
  end

  describe '#initialize' do
    subject { described_class.new(args.to_h) }
    let(:args) { Fabricate(:activity_metadata) }

    it 'sets the attributes' do
      expect(subject.id).to eq(args.id)
      expect(subject.task_token).to eq(args.task_token)
      expect(subject.attempt).to eq(args.attempt)
      expect(subject.workflow_run_id).to eq(args.workflow_run_id)
      expect(subject.workflow_id).to eq(args.workflow_id)
      expect(subject.workflow_name).to eq(args.workflow_name)
    end

    it 'returns frozen object' do
      expect(subject).to be_frozen
    end
  end
end
