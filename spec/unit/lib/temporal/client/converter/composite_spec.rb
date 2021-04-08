require 'temporal/client/converter/bytes'

describe Temporal::Client::Converter::Composite do
  let(:bytes_converter) { Temporal::Client::Converter::Bytes.new }
  let(:json_converter) { Temporal::Client::Converter::JSON.new }

  subject { described_class.new(converters: [bytes_converter, json_converter]) }

  describe 'encoding' do
    it 'tries converters until it finds a match' do
      payloads = [
        Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' =>  Temporal::Client::Converter::Bytes::ENCODING },
          data: 'test'.b
        ),
        Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' =>  Temporal::Client::Converter::JSON::ENCODING },
          data: '"test"'
        ),
      ]

      expect(bytes_converter).to receive(:to_payload).exactly(2).times.and_call_original
      expect(json_converter).to receive(:to_payload).once.and_call_original

      results = [subject.to_payload('test'.b), subject.to_payload('test')]

      expect(results).to eq(payloads)
    end
  end

  describe 'decoding' do
    it 'uses metadata to pick a converter' do
      payloads = [
        Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' =>  Temporal::Client::Converter::Bytes::ENCODING },
          data: 'test'.b
        ),
        Temporal::Api::Common::V1::Payload.new(
          metadata: { 'encoding' =>  Temporal::Client::Converter::JSON::ENCODING },
          data: '"test"'
        ),
      ]

      expect(bytes_converter).to receive(:from_payload).once.and_call_original
      expect(json_converter).to receive(:from_payload).once.and_call_original

      subject.from_payload(payloads[0])
      subject.from_payload(payloads[1])
    end

    it 'raises if there is no converter for an encoding' do
      payload = Temporal::Api::Common::V1::Payload.new(
        metadata: { 'encoding' => 'fake' }
      )

      expect { subject.from_payload(payload) }.to raise_error(Temporal::Client::Converter::Composite::ConverterNotFound)
    end
  end
end
