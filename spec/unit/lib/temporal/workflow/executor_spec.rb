require 'temporal/workflow/executor'
require 'temporal/workflow/history'
require 'temporal/workflow'

describe Temporal::Workflow::Executor do
  subject { described_class.new(workflow, history, workflow_metadata, config) }

  let(:workflow_started_event) { Fabricate(:api_workflow_execution_started_event, event_id: 1) }
  let(:history) do
    Temporal::Workflow::History.new([
                                     workflow_started_event,
                                     Fabricate(:api_workflow_task_scheduled_event, event_id: 2),
                                     Fabricate(:api_workflow_task_started_event, event_id: 3),
                                     Fabricate(:api_workflow_task_completed_event, event_id: 4)
                                   ])
  end
  let(:workflow) { TestWorkflow }
  let(:workflow_metadata) { Fabricate(:workflow_metadata) }
  let(:config) { Temporal::Configuration.new }

  class TestWorkflow < Temporal::Workflow
    def execute
      'test'
    end
  end

  describe '#run' do
    it 'runs a workflow' do
      allow(workflow).to receive(:execute_in_context).and_call_original

      subject.run

      expect(workflow)
        .to have_received(:execute_in_context)
              .with(
                an_instance_of(Temporal::Workflow::Context),
                nil
              )
    end

    it 'returns a complete workflow decision' do
      decisions = subject.run

      expect(decisions.length).to eq(1)

      decision_id, decision = decisions.first
      expect(decision_id).to eq(history.events.length + 1)
      expect(decision).to be_an_instance_of(Temporal::Workflow::Decision::CompleteWorkflow)
      expect(decision.result).to eq('test')
    end

    it 'generates workflow metadata' do
      allow(Temporal::Metadata::Workflow).to receive(:new).and_call_original
      workflow_started_event.WorkflowExecutionStartedEventAttributes.header =
        Fabricate(:header_thrift, fields: { 'Foo' => 'Bar' })

      subject.run

      event_attributes = workflow_started_event.workflowExecutionStartedEventAttributes
      expect(Temporal::Metadata::Workflow)
        .to have_received(:new)
              .with(
                namespace: workflow_metadata.namespace,
                id: workflow_metadata.workflow_id,
                name: event_attributes.workflowType.name,
                run_id: event_attributes.originalExecutionRunId,
                attempt: event_attributes.attempt,
                headers: { 'Foo' => 'Bar' },
                timeouts: {
                  execution: event_attributes.executionStartToCloseTimeoutSeconds,
                  task: event_attributes.taskStartToCloseTimeoutSeconds
                }
              )
    end
  end
end