require 'temporal/workflow'
require 'temporal/workflow/dispatcher'
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
end