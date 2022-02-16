require 'temporal/errors'

describe 'Temporal.describe_namespace', :integration do
  it 'returns a value' do
    namespace = integration_spec_namespace
    rescued = false
    begin
      Temporal.register_namespace(namespace)
    rescue Temporal::NamespaceAlreadyExistsFailure
      rescued = true
    end
    expect(rescued).to eq(true)
    result = Temporal.describe_namespace(namespace)
    expect(result).to be_an_instance_of(Temporal::Api::WorkflowService::V1::DescribeNamespaceResponse)
    expect(result.namespace_info.name).to eq(namespace)
    expect(result.namespace_info.state).to eq(:NAMESPACE_STATE_REGISTERED)
    expect(result.namespace_info.description).to_not eq(nil)
  end
end
