require 'temporal/workflow/context'

describe Temporal::Workflow::Context do
  let(:state_manager) { instance_double('Temporal::Workflow::StateManager') }
  let(:workflow_context) do
    Temporal::Workflow::Context.new(
      state_manager,
      nil,
      nil
    )
  end
  describe '#replay' do
    it 'gets value from state_manager' do
      allow(state_manager).to receive(:replay?).and_return true

      expect(workflow_context.replay?).to be true
      expect(state_manager).to have_received(:replay?)
    end
  end
end
