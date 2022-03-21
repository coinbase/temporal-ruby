describe 'Temporal.register_namespace' do
  it 'can register a new namespace' do
    # have to generate a new namespace on each run because currently can't delete namespaces
    name = "test_namespace_#{SecureRandom.uuid}"
    description = 'this is the description'
    retention_period = 30
    data = { test: 'value' }

    Temporal.register_namespace(name, description, retention_period: retention_period, data: data)

    # fetch the namespace from Temporal and check it exists and has the correct settings 
    # (need to wait a few seconds for temporal to catch up so try a few times)
    attempts = 0
    while attempts < 30 do
      attempts += 1
      
      begin
        result = Temporal.describe_namespace(name)
         
        expect(result.namespace_info.name).to eq(name)
        expect(result.namespace_info.data).to eq(data)
        expect(result.config.workflow_execution_retention_ttl.seconds).to eq(retention_period * 24 * 60 * 60)
        break
      rescue GRPC::NotFound
        sleep 0.5
      end
    end
  end

  it 'errors if attempting to register a namespace with the same name' do
    name = "test_namespace_#{SecureRandom.uuid}"
    Temporal.register_namespace(name)
    
    expect {Temporal.register_namespace(name)}.to raise_error(Temporal::NamespaceAlreadyExistsFailure, 'Namespace already exists.')
  end
end
