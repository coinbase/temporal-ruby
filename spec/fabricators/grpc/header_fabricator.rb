Fabricator(:api_header, from: Temporal::Api::Common::V1::Header) do
  fields { Google::Protobuf::Map.new(:string, :message, Temporal::Api::Common::V1::Payload) }
end
