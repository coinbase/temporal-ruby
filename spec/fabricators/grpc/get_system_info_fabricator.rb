Fabricator(:api_get_system_info, from: Temporalio::Api::WorkflowService::V1::GetSystemInfoResponse) do
  transient :sdk_metadata_capability

  server_version 'test-7.8.9'
  capabilities do |attrs|
    Temporalio::Api::WorkflowService::V1::GetSystemInfoResponse::Capabilities.new(
      sdk_metadata: attrs.fetch(:sdk_metadata, true)
    )
  end
end
