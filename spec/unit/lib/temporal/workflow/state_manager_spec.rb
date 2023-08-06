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
    let(:initial_search_attributes) do
      {
        'CustomAttribute1' => 42,
        'CustomAttribute2' => 10
      }
    end
    let(:start_workflow_execution_event) do
      Fabricate(:api_workflow_execution_started_event, search_attributes: initial_search_attributes)
    end
    let(:start_workflow_execution_event_no_search_attributes) do
      Fabricate(:api_workflow_execution_started_event)
    end
    let(:workflow_task_started_event) { Fabricate(:api_workflow_task_started_event, event_id: 2) }
    let(:upserted_attributes_1) do
      {
        'CustomAttribute3' => 'foo',
        'CustomAttribute2' => 8
      }
    end
    let(:upsert_search_attribute_event_1) do
      Fabricate(:api_upsert_search_attributes_event, search_attributes: upserted_attributes_1)
    end
    let(:upserted_attributes_2) do
      {
        'CustomAttribute3' => 'bar',
        'CustomAttribute4' => 10
      }
    end
    let(:upsert_search_attribute_event_2) do
      Fabricate(:api_upsert_search_attributes_event,
        event_id: 4,
        search_attributes: upserted_attributes_2)
    end
    let(:upsert_empty_search_attributes_event) do
      Fabricate(:api_upsert_search_attributes_event, search_attributes: {})
    end

    it 'initial merges with upserted' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new)

      window = Temporal::Workflow::History::Window.new
      window.add(Temporal::Workflow::History::Event.new(start_workflow_execution_event))
      window.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event_1))

      command = Temporal::Workflow::Command::UpsertSearchAttributes.new(
        search_attributes: upserted_attributes_1
      )

      state_manager.schedule(command)
      # Attributes from command are applied immediately, then merged when
      # history window is replayed below. This ensures newly upserted
      # search attributes are available immediately in workflow code.
      expect(state_manager.search_attributes).to eq(upserted_attributes_1)

      state_manager.apply(window)

      expect(state_manager.search_attributes).to eq(
        {
          'CustomAttribute1' => 42, # from initial (not overridden)
          'CustomAttribute2' => 8, # only from upsert
          'CustomAttribute3' => 'foo', # overridden by upsert
        }
      )
    end

    it 'initial and upsert treated as empty hash' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new)

      window = Temporal::Workflow::History::Window.new
      window.add(Temporal::Workflow::History::Event.new(start_workflow_execution_event_no_search_attributes))
      window.add(Temporal::Workflow::History::Event.new(upsert_empty_search_attributes_event))

      command = Temporal::Workflow::Command::UpsertSearchAttributes.new(search_attributes: {})
      expect(state_manager.search_attributes).to eq({})

      state_manager.schedule(command)
      state_manager.apply(window)

      expect(state_manager.search_attributes).to eq({})
    end


    it 'multiple upserts merge' do
      state_manager = described_class.new(Temporal::Workflow::Dispatcher.new)

      window_1 = Temporal::Workflow::History::Window.new
      window_1.add(Temporal::Workflow::History::Event.new(workflow_task_started_event))
      window_1.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event_1))

      command_1 = Temporal::Workflow::Command::UpsertSearchAttributes.new(search_attributes: upserted_attributes_1)
      state_manager.schedule(command_1)
      state_manager.apply(window_1)

      expect(state_manager.search_attributes).to eq(upserted_attributes_1)

      window_2 = Temporal::Workflow::History::Window.new
      window_2.add(Temporal::Workflow::History::Event.new(upsert_search_attribute_event_2))

      command_2 = Temporal::Workflow::Command::UpsertSearchAttributes.new(search_attributes: upserted_attributes_2)
      state_manager.schedule(command_2)
      state_manager.apply(window_2)

      expect(state_manager.search_attributes).to eq(
        {
          'CustomAttribute2' => 8,
          'CustomAttribute3' => 'bar',
          'CustomAttribute4' => 10,
        }
      )
    end
  end
end
