Fabricator(:api_header, from: Temporalio::Api::Common::V1::Header) do
  fields { Google::Protobuf::Map.new(:string, :message, Temporalio::Api::Common::V1::Payload) }
end
