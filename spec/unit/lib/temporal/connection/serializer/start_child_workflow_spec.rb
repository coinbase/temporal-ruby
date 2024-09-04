require 'temporal/connection/errors'
require 'temporal/workflow/command'
require 'temporal/connection/serializer/start_child_workflow'

describe Temporal::Connection::Serializer::StartChildWorkflow do
  let(:converter) do
    Temporal::ConverterWrapper.new(
      Temporal::Configuration::DEFAULT_CONVERTER,
      Temporal::Configuration::DEFAULT_PAYLOAD_CODEC
    )
  end
  let(:example_command) do
    Temporal::Workflow::Command::StartChildWorkflow.new(
      workflow_id: SecureRandom.uuid,
      workflow_type: '',
      input: nil,
      namespace: '',
      task_queue: '',
      retry_policy: nil,
      timeouts: { execution: 1, run: 1, task: 1 },
      headers: nil,
      memo: {},
      search_attributes: {},
    )
  end

  describe 'to_proto' do
    it 'raises an error if an invalid parent_close_policy is specified' do
      command = example_command
      command.parent_close_policy = :invalid

      expect do
        described_class.new(command, converter).to_proto
      end.to raise_error(Temporal::Connection::ArgumentError) do |e|
        expect(e.message).to eq("Unknown parent_close_policy '#{command.parent_close_policy}' specified")
      end
    end

    {
      nil => :PARENT_CLOSE_POLICY_UNSPECIFIED,
      :terminate => :PARENT_CLOSE_POLICY_TERMINATE,
      :abandon => :PARENT_CLOSE_POLICY_ABANDON,
      :request_cancel => :PARENT_CLOSE_POLICY_REQUEST_CANCEL,
    }.each do |policy_name, expected_parent_close_policy|
      it "successfully resolves a parent_close_policy of #{policy_name}" do
        command = example_command
        command.parent_close_policy = policy_name

        result = described_class.new(command, converter).to_proto
        attribs = result.start_child_workflow_execution_command_attributes
        expect(attribs.parent_close_policy).to eq(expected_parent_close_policy)
      end
    end
  end
end
