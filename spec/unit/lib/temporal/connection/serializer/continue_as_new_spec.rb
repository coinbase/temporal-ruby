require 'temporal/connection/serializer/continue_as_new'
require 'temporal/workflow/command'

describe Temporal::Connection::Serializer::ContinueAsNew do
  let(:config) { Temporal::Configuration.new }

  describe 'to_proto' do
    it 'produces a protobuf' do
      command = Temporal::Workflow::Command::ContinueAsNew.new(
        workflow_type: 'my-workflow-type',
        task_queue: 'my-task-queue',
        input: ['one', 'two'],
        timeouts: config.timeouts,
        headers: {'foo-header': 'bar'},
        memo: {'foo-memo': 'baz'},
      )

      result = described_class.new(command, config.converter).to_proto

      expect(result).to be_an_instance_of(Temporal::Api::Command::V1::Command)
      expect(result.command_type).to eql(
        :COMMAND_TYPE_CONTINUE_AS_NEW_WORKFLOW_EXECUTION
      )
      expect(result.continue_as_new_workflow_execution_command_attributes).not_to be_nil
      attribs = result.continue_as_new_workflow_execution_command_attributes

      expect(attribs.workflow_type.name).to eq('my-workflow-type')

      expect(attribs.task_queue.name).to eq('my-task-queue')

      expect(attribs.input.payloads[0].data).to eq('"one"')
      expect(attribs.input.payloads[1].data).to eq('"two"')

      expect(attribs.header.fields['foo-header'].data).to eq('"bar"')
      expect(attribs.memo.fields['foo-memo'].data).to eq('"baz"')
    end
  end
end
