require 'temporal/connection/serializer/continue_as_new'
require 'temporal/workflow/command'

describe Temporal::Connection::Serializer::ContinueAsNew do
  describe 'to_proto' do
    it 'produces a protobuf' do
      timeouts = {
        execution: 1000,
        run: 100,
        task: 10
      }
      command = Temporal::Workflow::Command::ContinueAsNew.new(
        workflow_type: 'my-workflow-type',
        task_queue: 'my-task-queue',
        input: ['one', 'two'],
        timeouts: timeouts,
        headers: {'foo-header': 'bar'},
        memo: {'foo-memo': 'baz'},
        search_attributes: {'foo-search-attribute': 'qux'},
      )

      result = described_class.new(command).to_proto

      expect(result).to be_an_instance_of(Temporalio::Api::Command::V1::Command)
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
      expect(attribs.search_attributes.indexed_fields['foo-search-attribute'].data).to eq('"qux"')

      expect(attribs.workflow_run_timeout.seconds).to eq(timeouts[:run])
      expect(attribs.workflow_task_timeout.seconds).to eq(timeouts[:task])
    end
  end
end
