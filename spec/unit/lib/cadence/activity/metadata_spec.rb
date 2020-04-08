require 'cadence/activity/metadata'

describe Cadence::Activity::Metadata do
  describe '.from_task' do
    subject { described_class.from_task(task) }
    let(:task) { Fabricate(:activity_task) }

    it 'generates metadata' do
      expect(subject.id).to eq(task.activityId)
      expect(subject.name).to eq(task.activityType.name)
      expect(subject.task_token).to eq(task.taskToken)
      expect(subject.attempt).to eq(task.attempt)
      expect(subject.workflow_run_id).to eq(task.workflowExecution.runId)
      expect(subject.workflow_id).to eq(task.workflowExecution.workflowId)
      expect(subject.workflow_name).to eq(task.workflowType.name)
      expect(subject.headers).to eq({})
    end

    context 'with headers' do
      let(:task) { Fabricate(:activity_task, headers: { 'Foo' => 'Bar' }) }

      it 'assigns headers' do
        expect(subject.headers).to eq('Foo' => 'Bar')
      end
    end
  end

  describe '#initialize' do
    subject { described_class.new(args.to_h) }
    let(:args) { Fabricate(:activity_metadata) }

    it 'sets the attributes' do
      expect(subject.id).to eq(args.id)
      expect(subject.name).to eq(args.name)
      expect(subject.task_token).to eq(args.task_token)
      expect(subject.attempt).to eq(args.attempt)
      expect(subject.workflow_run_id).to eq(args.workflow_run_id)
      expect(subject.workflow_id).to eq(args.workflow_id)
      expect(subject.workflow_name).to eq(args.workflow_name)
      expect(subject.headers).to eq(args.headers)
    end

    it 'returns frozen object' do
      expect(subject).to be_frozen
    end
  end
end
