require 'temporal/metadata'

describe Temporal::Metadata do
  describe '.generate_activity_metadata' do
    subject { described_class.generate_activity_metadata(data, namespace) }

    let(:data) { Fabricate(:api_activity_task) }
    let(:namespace) { 'test-namespace' }

    it 'generates metadata' do
      expect(subject.namespace).to eq(namespace)
      expect(subject.id).to eq(data.activity_id)
      expect(subject.name).to eq(data.activity_type.name)
      expect(subject.task_token).to eq(data.task_token)
      expect(subject.attempt).to eq(data.attempt)
      expect(subject.workflow_run_id).to eq(data.workflow_execution.run_id)
      expect(subject.workflow_id).to eq(data.workflow_execution.workflow_id)
      expect(subject.workflow_name).to eq(data.workflow_type.name)
      expect(subject.headers).to eq({})
    end

    context 'with headers' do
      let(:data) { Fabricate(:api_activity_task, headers: { 'Foo' => 'Bar' }) }

      it 'assigns headers' do
        expect(subject.headers).to eq('Foo' => 'Bar')
      end
    end
  end
  
  describe '.generate_workflow_task_metadata' do
    subject { described_class.generate_workflow_task_metadata(data, namespace) }

    let(:data) { Fabricate(:api_workflow_task) }
    let(:namespace) { 'test-namespace' }

    it 'generates metadata' do
      expect(subject.namespace).to eq(namespace)
      expect(subject.id).to eq(data.started_event_id)
      expect(subject.task_token).to eq(data.task_token)
      expect(subject.attempt).to eq(data.attempt)
      expect(subject.workflow_run_id).to eq(data.workflow_execution.run_id)
      expect(subject.workflow_id).to eq(data.workflow_execution.workflow_id)
      expect(subject.workflow_name).to eq(data.workflow_type.name)
    end
  end

  context '.generate_workflow_metadata' do
    subject { described_class.generate_workflow_metadata(event, task_metadata) }
    let(:event) { Temporal::Workflow::History::Event.new(Fabricate(:api_workflow_execution_started_event)) }
    let(:task_metadata) { Fabricate(:workflow_task_metadata) }
    let(:namespace) { nil }

    it 'generates metadata' do
      expect(subject.run_id).to eq(event.attributes.original_execution_run_id)
      expect(subject.workflow_id).to eq(task_metadata.workflow_id)
      expect(subject.attempt).to eq(event.attributes.attempt)
      expect(subject.headers).to eq({})
      expect(subject.memo).to eq({})
      expect(subject.namespace).to eq(task_metadata.namespace)
      expect(subject.task_queue).to eq(event.attributes.task_queue.name)
      expect(subject.run_started_at).to eq(event.timestamp)
    end

    context 'with headers' do
      let(:event) do
        Temporal::Workflow::History::Event.new(
          Fabricate(:api_workflow_execution_started_event, headers: { 'Foo' => 'Bar' })
        )
      end

      it 'assigns headers' do
        expect(subject.headers).to eq('Foo' => 'Bar')
      end
    end
  end
end
