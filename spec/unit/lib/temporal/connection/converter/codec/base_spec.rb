require 'temporal/connection/converter/codec/chain'

describe Temporal::Connection::Converter::Codec::Base do
  let(:payloads) do
    Temporalio::Api::Common::V1::Payloads.new(
      payloads: [
        Temporalio::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'json/plain' },
          data: '{}'.b
        )
      ]
    )
  end

  let(:base_codec) { described_class.new }

  describe '#encodes' do
    it 'returns nil if payloads is nil' do
      expect(base_codec.encodes(nil)).to be_nil
    end

    it 'encodes each payload in payloads' do
      expect(base_codec).to receive(:encode).with(payloads.payloads[0])
      base_codec.encodes(payloads)
    end

    it 'returns a new Payloads object with the encoded payloads' do
      encoded_payloads = Temporalio::Api::Common::V1::Payloads.new(
        payloads: [Temporalio::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'json/plain' },
          data: 'encoded_payload'.b
        )]
      )

      allow(base_codec).to receive(:encode).and_return('encoded_payload')

      expect(base_codec.encodes(payloads)).to eq(encoded_payloads)
    end
  end

  describe '#decodes' do
    it 'returns nil if payloads is nil' do
      expect(base_codec.decodes(nil)).to be_nil
    end

    it 'decodes each payload in payloads' do
      expect(base_codec).to receive(:decode).with(payloads.payloads[0])
      base_codec.decodes(payloads)
    end

    it 'returns a new Payloads object with the decoded payloads' do
      decoded_payloads = Temporalio::Api::Common::V1::Payloads.new(
        payloads: [Temporalio::Api::Common::V1::Payload.new(
          metadata: { 'encoding' => 'json/plain' },
          data: 'decoded_payload'.b
        )]
      )

      allow(base_codec).to receive(:decode).and_return('decoded_payload')

      expect(base_codec.decodes(payloads)).to eq(decoded_payloads)
    end
  end

  describe '#encode' do
    it 'raises a NotImplementedError' do
      expect { base_codec.encode }.to raise_error(NotImplementedError)
    end
  end

  describe '#decode' do
    it 'raises a NotImplementedError' do
      expect { base_codec.decode }.to raise_error(NotImplementedError)
    end
  end
end
