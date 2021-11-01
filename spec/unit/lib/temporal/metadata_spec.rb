require 'temporal/metadata'

describe Temporal::Metadata do
  describe '.generate' do
    subject { described_class.generate(type, data, namespace) }

    context 'with activity type' do
      let(:type) { described_class::ACTIVITY_TYPE }
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

    context 'with workflow task type' do
      let(:type) { described_class::WORKFLOW_TASK_TYPE }
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

    context 'with unknown type' do
      let(:type) { :unknown }
      let(:data) { nil }
      let(:namespace) { nil }

      it 'raises' do
        expect { subject }.to raise_error(Temporal::InternalError, 'Unsupported metadata type')
      end
    end
  end
end
