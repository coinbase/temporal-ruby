require 'securerandom'
require 'time'
require 'temporal/connection/serializer/upsert_search_attributes'
require 'temporal/workflow/command'

describe Temporal::Connection::Serializer::UpsertSearchAttributes do
  let(:config) { Temporal::Configuration.new }

  it 'produces a protobuf that round-trips' do
    expected_attributes = {
      'CustomStringField' => 'moo',
      'CustomBoolField' => true,
      'CustomDoubleField' => 3.14,
      'CustomIntField' => 0,
      'CustomKeywordField' => SecureRandom.uuid,
      'CustomDatetimeField' => Time.now.to_i
    }

    command = Temporal::Workflow::Command::UpsertSearchAttributes.new(
      search_attributes: expected_attributes
    )

    result = described_class.new(command, config.converter).to_proto
    expect(result).to be_an_instance_of(Temporal::Api::Command::V1::Command)
    expect(result.command_type).to eql(
      :COMMAND_TYPE_UPSERT_WORKFLOW_SEARCH_ATTRIBUTES
    )
    command_attributes = result.upsert_workflow_search_attributes_command_attributes
    expect(command_attributes).not_to be_nil
    actual_attributes = config.converter.from_payload_map(command_attributes&.search_attributes&.indexed_fields)
    expect(actual_attributes).to eql(expected_attributes)

  end
end
