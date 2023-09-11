require 'temporal/middleware/chain'
require 'temporal/workflow/executor'
require 'temporal/workflow/history'
require 'temporal/workflow'
require 'temporal/workflow/task_processor'
require 'temporal/workflow/query_registry'

describe Temporal::Workflow::Executor do
  subject { described_class.new(workflow, history, workflow_metadata, config, false, middleware_chain) }

  let(:connection) { instance_double('Temporal::Connection::GRPC') }
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
  let(:middleware_chain) { Temporal::Middleware::Chain.new }

  before do
    allow(Temporal::Connection).to receive(:generate).and_return(connection)
  end

  class TestWorkflow < Temporal::Workflow
    def execute
      'test'
    end
  end

  describe '#run' do
    it 'runs a workflow' do
      allow(workflow).to receive(:execute_in_context).and_call_original
      expect(middleware_chain).to receive(:invoke).and_call_original

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

      expect(decisions.commands.length).to eq(1)
      expect(decisions.new_sdk_flags_used).to be_empty

      decision_id, decision = decisions.commands.first
      expect(decision_id).to eq(history.events.length + 1)
      expect(decision).to be_an_instance_of(Temporal::Workflow::Command::CompleteWorkflow)
      expect(decision.result).to eq('test')
    end

    context 'history with signal' do
      let(:history) do
        Temporal::Workflow::History.new([
                                          workflow_started_event,
                                          Fabricate(:api_workflow_execution_signaled_event, event_id: 2),
                                          Fabricate(:api_workflow_task_scheduled_event, event_id: 3),
                                          Fabricate(:api_workflow_task_started_event, event_id: 4)
                                        ])
      end
      let(:system_info) { Fabricate(:api_get_system_info) }

      context 'signals first config enabled' do
        it 'set signals first sdk flag' do
          allow(connection).to receive(:get_system_info).and_return(system_info)

          decisions = subject.run

          expect(decisions.commands.length).to eq(1)
          expect(decisions.new_sdk_flags_used).to eq(Set.new([Temporal::Workflow::SDKFlags::HANDLE_SIGNALS_FIRST]))
        end
      end

      context 'signals first config disabled' do
        let(:config) { Temporal::Configuration.new.tap { |c| c.legacy_signals = true } }
        it 'no sdk flag' do
          decisions = subject.run

          expect(decisions.commands.length).to eq(1)
          expect(decisions.new_sdk_flags_used).to be_empty
        end
      end
    end

    it 'generates workflow metadata' do
      allow(Temporal::Metadata::Workflow).to receive(:new)
      payload = Temporalio::Api::Common::V1::Payload.new(
        metadata: { 'encoding' => 'json/plain' },
        data: '"bar"'.b
      )
      header =
        Google::Protobuf::Map.new(:string, :message, Temporalio::Api::Common::V1::Payload, { 'Foo' => payload })
      workflow_started_event.workflow_execution_started_event_attributes.header =
        Fabricate(:api_header, fields: header)

      subject.run

      event_attributes = workflow_started_event.workflow_execution_started_event_attributes
      expect(Temporal::Metadata::Workflow)
        .to have_received(:new)
        .with(
          namespace: workflow_metadata.namespace,
          id: workflow_metadata.workflow_id,
          name: event_attributes.workflow_type.name,
          run_id: event_attributes.original_execution_run_id,
          parent_id: nil,
          parent_run_id: nil,
          attempt: event_attributes.attempt,
          task_queue: event_attributes.task_queue.name,
          headers: { 'Foo' => 'bar' },
          run_started_at: workflow_started_event.event_time.to_time,
          memo: {}
        )
    end
  end

  describe '#process_queries' do
    let(:query_registry) { Temporal::Workflow::QueryRegistry.new }
    let(:query_1_result) { 42 }
    let(:query_2_error) { StandardError.new('Test query failure') }
    let(:queries) do
      {
        '1' => Temporal::Workflow::TaskProcessor::Query.new(Fabricate(:api_workflow_query, query_type: 'success')),
        '2' => Temporal::Workflow::TaskProcessor::Query.new(Fabricate(:api_workflow_query, query_type: 'failure')),
        '3' => Temporal::Workflow::TaskProcessor::Query.new(Fabricate(:api_workflow_query, query_type: 'unknown'))
      }
    end

    before do
      allow(Temporal::Workflow::QueryRegistry).to receive(:new).and_return(query_registry)
      query_registry.register('success') { query_1_result }
      query_registry.register('failure') { raise query_2_error }
    end

    it 'returns query results' do
      results = subject.process_queries(queries)

      expect(results.length).to eq(3)
      expect(results['1']).to be_a(Temporal::Workflow::QueryResult::Answer)
      expect(results['1'].result).to eq(query_1_result)
      expect(results['2']).to be_a(Temporal::Workflow::QueryResult::Failure)
      expect(results['2'].error).to eq(query_2_error)
      expect(results['3']).to be_a(Temporal::Workflow::QueryResult::Failure)
      expect(results['3'].error).to be_a(Temporal::QueryFailed)
      expect(results['3'].error.message).to eq("Workflow did not register a handler for 'unknown'. KnownQueryTypes=[success, failure]")
    end
  end
end
