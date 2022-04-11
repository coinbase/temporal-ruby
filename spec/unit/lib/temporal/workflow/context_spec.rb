require 'temporal/workflow'
require 'temporal/workflow/context'
require 'time'

class MyTestWorkflow < Temporal::Workflow; end

describe Temporal::Workflow::Context do
  let(:state_manager) { instance_double('Temporal::Workflow::StateManager') }
  let(:dispatcher) { instance_double('Temporal::Workflow::Dispatcher') }
  let(:query_registry) { instance_double('Temporal::Workflow::QueryRegistry') }
  let(:metadata) { instance_double('Temporal::Metadata::Workflow') }
  let(:workflow_context) do
    Temporal::Workflow::Context.new(
      state_manager,
      dispatcher,
      MyTestWorkflow,
      metadata,
      Temporal.configuration,
      query_registry
    )
  end

  describe '#on_query' do
    let(:handler) { Proc.new {} }

    before { allow(query_registry).to receive(:register) }

    it 'registers a query with the query registry' do
      workflow_context.on_query('test-query', &handler)

      expect(query_registry).to have_received(:register).with('test-query') do |&block|
        expect(block).to eq(handler)
      end
    end
  end

  describe '#upsert_search_attributes' do
    it 'does not accept nil' do
      expect do
        workflow_context.upsert_search_attributes(nil)
      end.to raise_error(ArgumentError, 'search_attributes cannot be nil')
    end

    it 'requires a hash' do
      expect do
        workflow_context.upsert_search_attributes(['array_not_supported'])
      end.to raise_error(ArgumentError, 'for search_attributes, expecting a Hash, not Array')
    end

    it 'requires a non-empty hash' do
      expect do
        workflow_context.upsert_search_attributes({})
      end.to raise_error(ArgumentError, 'Cannot upsert an empty hash for search_attributes, as this would do nothing.')
    end

    it 'creates a command to execute the request' do
      expect(state_manager).to receive(:schedule)
        .with an_instance_of(Temporal::Workflow::Command::UpsertSearchAttributes)
      workflow_context.upsert_search_attributes({ 'CustomIntField' => 5 })
    end

    it 'converts a Time to the ISO8601 UTC format expected by the Temporal server' do
      time = Time.now
      allow(state_manager).to receive(:schedule)
        .with an_instance_of(Temporal::Workflow::Command::UpsertSearchAttributes)

      expect(
        workflow_context.upsert_search_attributes({'CustomDatetimeField' => time})
      ).to eq({ 'CustomDatetimeField' => time.utc.iso8601 })
    end
  end
end
