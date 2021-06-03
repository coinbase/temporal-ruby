require 'temporal/client/serializer/continue_as_new'
require 'temporal/workflow/command'

describe Temporal::Client::Serializer::ContinueAsNew do
  subject { described_class.new(payload_converters: [bytes_converter, json_converter]) }

  describe 'to_proto' do
    it 'produces a protobuf' do
      command = Temporal::Workflow::Command::ContinueAsNew.new(
        workflow_type: 'Test',
        task_queue: 'Test',
        input: ['one', 'two'],
        timeouts: Temporal.configuration.timeouts
      )

    result = described_class.new(command).to_proto

    expect(result).to be_an_instance_of(Temporal::Api::Command::V1::Command)
    expect(result.command_type).to eql(
      :COMMAND_TYPE_CONTINUE_AS_NEW_WORKFLOW_EXECUTION
    )
    end
  end
end
