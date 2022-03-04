require 'temporal/workflow'
require 'temporal/workflow/context'

class MyTestWorkflow < Temporal::Workflow; end

describe Temporal::Workflow::Context do
  let(:state_manager) { instance_double('Temporal::Workflow::StateManager') }
  let(:dispatcher) { instance_double('Temporal::Workflow::Dispatcher') }
  let(:metadata) { instance_double('Temporal::Metadata::Workflow') }
  let(:workflow_context) {
    Temporal::Workflow::Context.new(state_manager, dispatcher, MyTestWorkflow, metadata, Temporal.configuration)
  }

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
      workflow_context.upsert_search_attributes({'CustomIntField' => 5})
    end
  end

  describe '#history_replaying?' do
    it 'when true' do
      expect(state_manager).to receive(:replay?).and_return(true)
      expect(workflow_context.history_replaying?).to be(true)
    end

    it 'when false' do
      expect(state_manager).to receive(:replay?).and_return(false)
      expect(workflow_context.history_replaying?).to be(false)
    end
  end
end
