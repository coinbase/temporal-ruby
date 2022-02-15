describe 'Temporal.list_namespaces', :integration do
  it 'returns the correct values' do
    result = Temporal.list_namespaces(page_size: 100)
    expect(result).to be_an_instance_of(Temporal::Api::WorkflowService::V1::ListNamespacesResponse)
  end
end
