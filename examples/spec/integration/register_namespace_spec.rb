require 'workflows/timeout_workflow'

describe 'Temporal.register_namespace' do
  it 'can register a new namespace' do
    # have to generate a new namespace on each run because currently can't delete namespaces
    name = "test_namespace_#{SecureRandom.uuid}"
    description = 'this is the description'
    retention_period = 30
    namespace_data = { test: 'value' }

    result = Temporal.register_namespace(name, description, retention_period: retention_period, namespace_data: namespace_data)
    expect(result).to be_an_instance_of(Temporal::Api::WorkflowService::V1::RegisterNamespaceResponse)

    # fetch the namespace from Temporal and check it exists and has the correct settings
    found_namespace = nil
    next_page_token = ''

    while found_namespace.nil?
      result = Temporal.list_namespaces(page_size: 100, next_page_token: next_page_token)
      result.namespaces.each do |namespace|
        if namespace.namespace_info.name == name
          found_namespace = namespace
          break
        end
      end

      if result.next_page_token == ''
        break
      else
        next_page_token = result.next_page_token
      end
    end

    expect(found_namespace).to_not eq(nil)
    expect(found_namespace.namespace_info.name).to eq(name)
    expect(found_namespace.namespace_info.data).to eq(namespace_data)
    expect(found_namespace.config.workflow_execution_retention_ttl.seconds).to eq(retention_period * 24 * 60 * 60)
  end

  it 'errors if attempting to register a namespace with the same name' do
    name = "test_namespace_#{SecureRandom.uuid}"
    Temporal.register_namespace(name)
    
    expect {Temporal.register_namespace(name)}.to raise_error(Temporal::NamespaceAlreadyExistsFailure, 'Namespace already exists.')
  end
end
