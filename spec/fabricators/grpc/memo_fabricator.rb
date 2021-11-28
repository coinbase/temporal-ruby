Fabricator(:memo, from: Temporal::Api::Common::V1::Memo) do
  fields do
    Google::Protobuf::Map.new(:string, :message, Temporal::Api::Common::V1::Payload).tap do |m|
      m['foo'] = Temporal.configuration.converter.to_payload('bar')
    end
  end
end
