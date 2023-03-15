require 'temporal/workflow'
require 'temporal/workflow/dispatcher'
require 'temporal/workflow/history/event'
require 'temporal/workflow/history/window'
require 'temporal/workflow/state_manager'
require 'temporal/errors'

describe Temporal::Workflow::StateManager do

  describe '#schedule' do
    class MyWorkflow < Temporal::Workflow; end

    # These are all "terminal" commands
    [
      Temporal::Workflow::Command::ContinueAsNew.new(
        workflow_type: MyWorkflow,
        task_queue: 'dummy',
      ),
      Temporal::Workflow::Command::FailWorkflow.new(
        exception: StandardError.new('dummy'),
      ),
      Temporal::Workflow::Command::CompleteWorkflow.new(
        result: 5,
      ),
    ].each do |terminal_command|
      it "fails to validate if #{terminal_command.class} is not the last command scheduled" do
        state_manager = described_class.new(Temporal::Workflow::Dispatcher.new)

        next_command = Temporal::Workflow::Command::RecordMarker.new(
          name: Temporal::Workflow::StateManager::RELEASE_MARKER,
          details: 'dummy',
        )

        state_manager.schedule(terminal_command)
        expect do
          state_manager.schedule(next_command)
        end.to raise_error(Temporal::WorkflowAlreadyCompletingError)
      end
    end
  end

  describe '#search_attributes' do
    let(:start_workflow_execution_event) { Fabricate(:api_workflow_execution_started_event) }
    let(:upsert_search_attribute_event) { Fabricate(:api_upsert_search_attributes_event) }

    it 'initial merges with upserted' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new)

      window = Temporal::Workflow::History::Window.new
      window.add(Temporal::Workflow::History::Event.new(start_workflow_execution_event))
      window.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event))

      command = Temporal::Workflow::Command::UpsertSearchAttributes.new
      # No arguments because the arguments do not need to match

      state_manager.schedule(command)
      state_manager.apply(window)

      expect(state_manager.search_attributes).to eq(
        {
          'CustomIntAttribute' => 42, # from initial
          'CustomStringAttribute' => 'foo' # from upsert
        }
      )
    end
  end
end
