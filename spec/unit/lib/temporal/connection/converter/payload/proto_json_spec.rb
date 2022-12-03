require 'temporal/connection/converter/payload/proto_json'

describe Temporal::Connection::Converter::Payload::ProtoJSON do
  subject { described_class.new }

  describe 'round trip' do
    it 'converts' do
      # Temporal::Api::Common::V1::Payload is a protobuf.
      # Using it as the "input" here to show the roundtrip.
      # #to_payload will return a wrapped Payload around this one.
      input = Temporal::Api::Common::V1::Payload.new(
        metadata: { 'hello' => 'world' },
        data: 'hello world',
      )

      expect(subject.from_payload(subject.to_payload(input))).to eq(input)
    end
  end

  it 'skips if not proto message' do
    input = { hello: 'world' }

    expect(subject.to_payload(input)).to be nil
  end

  # DO NOT MERGE THIS UPSTREAM TO COINBASE
  it 'exemptions' do
    data = '{"name":"foo"}'
    Temporal::Connection::Converter::Payload::ProtoJSON::SPECIAL_STRIPE_WORKFLOW_PAYLOAD_TYPES.each do |message_type|
      fake_payload = Struct.new(:metadata, :data).new({ 'messageType' => message_type }, data)
      data_out = subject.from_payload(fake_payload)
      expect(data_out).to eq({ 'name' => 'foo' })
    end
  end
end
