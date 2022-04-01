require 'temporal/converter_wrapper'
require 'temporal/connection/converter/payload/bytes'
require 'temporal/connection/converter/payload/nil'
require 'temporal/connection/converter/composite'

describe Temporal::ConverterWrapper do
  subject { described_class.new(converter) }
  let(:converter) do
    Temporal::Connection::Converter::Composite.new(payload_converters: [
      Temporal::Connection::Converter::Payload::Bytes.new,
      Temporal::Connection::Converter::Payload::Nil.new
    ])
  end
  let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes, payload_nil]) }
  let(:payload_bytes) { Fabricate(:api_payload_bytes, bytes: 'test-payload') }
  let(:payload_nil) { Fabricate(:api_payload_nil) }

  describe '#from_payloads' do
    it 'converts' do
      expect(subject.from_payloads(payloads)).to eq(['test-payload', nil])
    end
  end

  describe '#from_payload' do
    it 'converts' do
      expect(subject.from_payload(payload_bytes)).to eq('test-payload')
    end
  end

  describe '#from_result_payloads' do
    it 'converts' do
      expect(subject.from_result_payloads(payloads)).to eq('test-payload')
    end
  end

  describe '#from_details_payloads' do
    it 'converts first payload' do
      expect(subject.from_details_payloads(payloads)).to eq('test-payload')
    end
  end

  describe '#from_signal_payloads' do
    it 'converts first payload' do
      expect(subject.from_signal_payloads(payloads)).to eq('test-payload')
    end
  end

  describe '#from_payload_map' do
    let(:payload_map) do
      Google::Protobuf::Map.new(:string, :message, Temporal::Api::Common::V1::Payload).tap do |m|
        m['first'] = payload_bytes
        m['second'] = payload_nil
      end
    end

    it 'converts first payload' do
      expect(subject.from_payload_map(payload_map))
        .to eq('first' => 'test-payload', 'second' => nil)
    end
  end

  describe '#to_payloads' do
    it 'converts' do
      expect(subject.to_payloads(['test-payload'.b, nil])).to eq(payloads)
    end
  end

  describe '#to_payload' do
    it 'converts' do
      expect(subject.to_payload('test-payload'.b)).to eq(payload_bytes)
    end
  end

  describe '#to_result_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts' do
      expect(subject.to_result_payloads('test-payload'.b)).to eq(payloads)
    end
  end

  describe '#to_details_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts' do
      expect(subject.to_details_payloads('test-payload'.b)).to eq(payloads)
    end
  end

  describe '#to_signal_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts' do
      expect(subject.to_signal_payloads('test-payload'.b)).to eq(payloads)
    end
  end

  describe '#to_payload_map' do
    let(:payload_map) { { first: payload_bytes, second: payload_nil } }

    it 'converts' do
      expect(subject.to_payload_map(first: 'test-payload'.b, second: nil)).to eq(payload_map)
    end
  end
end
