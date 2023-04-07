require 'temporal/connection/converter/codec/chain'

describe Temporal::Connection::Converter::Codec::Chain do
  let(:codec1) { double('PayloadCodec1') }
  let(:codec2) { double('PayloadCodec2') }
  let(:codec3) { double('PayloadCodec3') }

  let(:payload_1) do
    Temporalio::Api::Common::V1::Payload.new(
      metadata: { 'encoding' => 'binary/plain' },
      data: 'payload_1'.b
    )
  end
  let(:payload_2) do
    Temporalio::Api::Common::V1::Payload.new(
      metadata: { 'encoding' => 'binary/plain' },
      data: 'payload_2'.b
    )
  end
  let(:payload_3) do
    Temporalio::Api::Common::V1::Payload.new(
      metadata: { 'encoding' => 'binary/plain' },
      data: 'payload_3'.b
    )
  end
  let(:payload_4) do
    Temporalio::Api::Common::V1::Payload.new(
      metadata: { 'encoding' => 'binary/plain' },
      data: 'payload_4'.b
    )
  end

  subject { described_class.new(payload_codecs: [codec1, codec2, codec3]) }

  describe '#encode' do
    it 'applies payload codecs in reverse order' do
      expect(codec3).to receive(:encode).with(payload_1).and_return(payload_2)
      expect(codec2).to receive(:encode).with(payload_2).and_return(payload_3)
      expect(codec1).to receive(:encode).with(payload_3).and_return(payload_4)

      result = subject.encode(payload_1)

      expect(result.metadata).to eq(payload_4.metadata)
      expect(result.data).to eq(payload_4.data)
    end
  end

  describe '#decode' do
    it 'applies payload codecs in the original order' do
      expect(codec1).to receive(:decode).with(payload_1).and_return(payload_2)
      expect(codec2).to receive(:decode).with(payload_2).and_return(payload_3)
      expect(codec3).to receive(:decode).with(payload_3).and_return(payload_4)

      result = subject.decode(payload_1)

      expect(result.metadata).to eq(payload_4.metadata)
      expect(result.data).to eq(payload_4.data)
    end
  end
end
