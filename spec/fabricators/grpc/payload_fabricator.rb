require 'temporal/connection/converter/payload/nil'

Fabricator(:api_payload, from: Temporal::Api::Common::V1::Payload) do
  metadata { Google::Protobuf::Map.new(:string, :bytes) }
end

Fabricator(:api_payload_nil, from: :api_payload) do
  metadata do
    Google::Protobuf::Map.new(:string, :bytes).tap do |m|
      m['encoding'] = Temporal::Connection::Converter::Payload::Nil::ENCODING
    end
  end
end

Fabricator(:api_payload_bytes, from: :api_payload) do
  transient :bytes

  metadata do
    Google::Protobuf::Map.new(:string, :bytes).tap do |m|
      m['encoding'] = Temporal::Connection::Converter::Payload::Bytes::ENCODING
    end
  end

  data { |attrs| attrs.fetch(:bytes, 'foobar') }
end
