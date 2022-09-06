require 'temporal/connection/converter/payload/json'

describe Temporal::Connection::Converter::Payload::ProtoJSON do
  subject { described_class.new }

  describe 'round trip' do
    it 'converts' do
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
end
