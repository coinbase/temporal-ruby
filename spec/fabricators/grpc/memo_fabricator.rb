Fabricator(:memo, from: Temporalio::Api::Common::V1::Memo) do
  fields do
    Google::Protobuf::Map.new(:string, :message, Temporalio::Api::Common::V1::Payload).tap do |m|
      m['foo'] = TEST_CONVERTER.to_payload('bar')
    end
  end
end
