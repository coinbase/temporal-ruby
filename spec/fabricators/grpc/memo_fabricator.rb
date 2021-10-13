Fabricator(:memo, from: Temporal::Api::Common::V1::Memo) do
  fields { Google::Protobuf::Map.new(:string, :message, Temporal::Api::Common::V1::Payload) }
end
  