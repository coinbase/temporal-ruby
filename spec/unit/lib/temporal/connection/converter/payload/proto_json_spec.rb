require 'temporal/connection/converter/payload/proto_json'

describe Temporal::Connection::Converter::Payload::ProtoJSON do
  subject { described_class.new }

  describe 'round trip' do
    it 'converts' do
      # Temporalio::Api::Common::V1::Payload is a protobuf.
      # Using it as the "input" here to show the roundtrip.
      # #to_payload will return a wrapped Payload around this one.
      input = Temporalio::Api::Common::V1::Payload.new(
        metadata: { 'hello' => 'world' },
        data: 'hello world',
      )

      expect(subject.from_payload(subject.to_payload(input))).to eq(input)
    end

    it 'encodes special characters' do
      input = Temporalio::Api::Common::V1::Payload.new(
        metadata: { 'it’ll work!' => 'bytebytebyte' },
      )
      expect(subject.from_payload(subject.to_payload(input))).to eq(input)
    end
  end

  it 'skips if not proto message' do
    input = { hello: 'world' }

    expect(subject.to_payload(input)).to be nil
  end
end
