require 'temporal/client'

describe Temporal::Client do
  describe 'converter' do
    subject { described_class.converter }

    describe 'round trip' do
      it 'safely handles non-ASCII encodable UTF characters' do
        input = { 'one' => 'one', two: :two, ':three' => '☻' }

        expect(subject.from_payload(subject.to_payload(input))).to eq(input)
      end

      it 'encodes a single array argument as one payload' do
        input = [1]

        expect(subject.from_payloads(subject.to_payloads(input))).to eq([input])
      end

      it 'encodes multiple arguments as separate payloads' do
        input1 = [1]
        input2 = [2]

        expect(subject.from_payloads(subject.to_payloads(input1, input2))).to eq([input1, input2])
      end
    end

    describe 'for nil payload' do
      it 'encodes to a null payload' do
        payload = Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'binary/null' }
        )

        expect(subject.to_payload(nil)).to eq(payload)
      end

      it 'decodes an null payload to nil' do
        payload = Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'binary/null' }
        )

        expect(subject.from_payload(payload)).to eq(nil)
      end
    end

    describe 'for a bytestring payload' do
      it 'encodes to a binary/plain payload' do
        payload = Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'binary/plain' },
          data: 'test'.b
        )

        expect(subject.to_payload('test'.b)).to eq(payload)
      end

      it 'decodes a binary/plain payload to a byte string' do
        payload = Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'binary/plain' },
          data: 'test'.b
        )

        expect(subject.from_payload(payload)).to eq('test'.b)
        expect(subject.from_payload(payload).encoding).to eq(Encoding::ASCII_8BIT)
      end
    end

    describe 'for multiple payloads' do
      it 'returns an array with the right data' do
        payloads = Temporal::Api::Common::V1::Payloads.new(
          payloads: [
            Temporal::Api::Common::V1::Payload.new(
              metadata: { 'encoding' => 'binary/plain' },
              data: 'test'.b
            ),
            Temporal::Api::Common::V1::Payload.new(
              metadata: { 'encoding' => 'json/plain' },
              data: '{"test":{"foo":2}}'
            ),
          ]
        )

        expect(subject.from_payloads(payloads)).to eq([
          'test'.b,
          { 'test' => { 'foo' => 2 } }
        ])
      end
    end
  end
end
