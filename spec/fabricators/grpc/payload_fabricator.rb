Fabricator(:api_payload, from: Temporalio::Api::Common::V1::Payload) do
  metadata { Google::Protobuf::Map.new(:string, :bytes) }
end
