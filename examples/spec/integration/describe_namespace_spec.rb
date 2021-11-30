require 'temporal/errors'

describe 'Temporal.describe_namespace' do
  it 'returns a value' do
    description = 'Namespace for temporal-ruby integration test'
    begin
      Temporal.register_namespace('a_test_namespace', description)
    rescue Temporal::NamespaceAlreadyExistsFailure
    end
    result = Temporal.describe_namespace('a_test_namespace')
    expect(result).to be_an_instance_of(Temporal::Api::WorkflowService::V1::DescribeNamespaceResponse)
    expect(result.namespace_info.name).to eq('a_test_namespace')
    expect(result.namespace_info.state).to eq(:NAMESPACE_STATE_REGISTERED)
    expect(result.namespace_info.description).to eq(description)
  end
end
