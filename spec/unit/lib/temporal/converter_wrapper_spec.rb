require 'temporal/converter_wrapper'
require 'temporal/connection/converter/payload/bytes'
require 'temporal/connection/converter/payload/nil'
require 'temporal/connection/converter/composite'

describe Temporal::ConverterWrapper do
  class TestCodec < Temporal::Connection::Converter::Codec::Base
    def encode(payload)
      return payload
    end

    def decode(payload)
      return payload
    end
  end

  subject { described_class.new(converter, codec) }
  let(:converter) do
    Temporal::Connection::Converter::Composite.new(payload_converters: [
      Temporal::Connection::Converter::Payload::Bytes.new,
      Temporal::Connection::Converter::Payload::Nil.new
    ])
  end
  let(:codec) { Temporal::Connection::Converter::Codec::Chain.new(payload_codecs: [TestCodec.new]) }
  let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes, payload_nil]) }
  let(:payload_bytes) { Fabricate(:api_payload_bytes, bytes: 'test-payload') }
  let(:payload_nil) { Fabricate(:api_payload_nil) }

  before do
    allow(codec).to receive(:encode).and_call_original
    allow(codec).to receive(:encodes).and_call_original
    allow(codec).to receive(:decode).and_call_original
    allow(codec).to receive(:decodes).and_call_original
  end

  describe '#from_payloads' do
    it 'decodes and converts' do
      expect(subject.from_payloads(payloads)).to eq(['test-payload', nil])
      expect(codec).to have_received(:decodes)
    end
  end

  describe '#from_payload' do
    it 'decodes and converts' do
      expect(subject.from_payload(payload_bytes)).to eq('test-payload')
      expect(codec).to have_received(:decode)
    end
  end

  describe '#from_payload_map_without_codec' do
    let(:payload_map) do
      Google::Protobuf::Map.new(:string, :message, Temporalio::Api::Common::V1::Payload).tap do |m|
        m['first'] = payload_bytes
        m['second'] = payload_nil
      end
    end

    it 'converts' do
      expect(subject.from_payload_map_without_codec(payload_map))
        .to eq('first' => 'test-payload', 'second' => nil)
      expect(codec).not_to have_received(:decode)
    end
  end

  describe '#from_result_payloads' do
    it 'decodes and converts' do
      expect(subject.from_result_payloads(payloads)).to eq('test-payload')
      expect(codec).to have_received(:decodes)
    end
  end

  describe '#from_details_payloads' do
    it 'decodes and converts first payload' do
      expect(subject.from_details_payloads(payloads)).to eq('test-payload')
      expect(codec).to have_received(:decodes)
    end
  end

  describe '#from_signal_payloads' do
    it 'decodes and converts first payload' do
      expect(subject.from_signal_payloads(payloads)).to eq('test-payload')
      expect(codec).to have_received(:decodes)
    end
  end

  describe '#from_query_payloads' do
    it 'decodes and converts first payload' do
      expect(subject.from_query_payloads(payloads)).to eq('test-payload')
      expect(codec).to have_received(:decodes)
    end
  end

  describe '#from_payload_map' do
    let(:payload_map) do
      Google::Protobuf::Map.new(:string, :message, Temporalio::Api::Common::V1::Payload).tap do |m|
        m['first'] = payload_bytes
        m['second'] = payload_nil
      end
    end

    it 'decodes and converts first payload' do
      expect(subject.from_payload_map(payload_map))
        .to eq('first' => 'test-payload', 'second' => nil)
      expect(codec).to have_received(:decode).twice
    end
  end

  describe '#to_payloads' do
    it 'converts and encodes' do
      expect(subject.to_payloads(['test-payload'.b, nil])).to eq(payloads)
      expect(codec).to have_received(:encodes)
    end
  end

  describe '#to_payload' do
    it 'converts and encodes' do
      expect(subject.to_payload('test-payload'.b)).to eq(payload_bytes)
      expect(codec).to have_received(:encode)
    end
  end

  describe '#to_payload_map_without_codec' do
    let(:payload_map) { { first: payload_bytes, second: payload_nil } }

    it 'converts' do
      expect(subject.to_payload_map_without_codec(first: 'test-payload'.b, second: nil)).to eq(payload_map)
      expect(codec).not_to have_received(:encode)
    end
  end

  describe '#to_result_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts and encodes' do
      expect(subject.to_result_payloads('test-payload'.b)).to eq(payloads)
      expect(codec).to have_received(:encodes)
    end
  end

  describe '#to_details_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts and encodes' do
      expect(subject.to_details_payloads('test-payload'.b)).to eq(payloads)
      expect(codec).to have_received(:encodes)
    end
  end

  describe '#to_signal_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts and encodes' do
      expect(subject.to_signal_payloads('test-payload'.b)).to eq(payloads)
      expect(codec).to have_received(:encodes)
    end
  end

  describe '#to_query_payloads' do
    let(:payloads) { Fabricate(:api_payloads, payloads_array: [payload_bytes]) }

    it 'converts and encodes' do
      expect(subject.to_query_payloads('test-payload'.b)).to eq(payloads)
      expect(codec).to have_received(:encodes)
    end
  end

  describe '#to_payload_map' do
    let(:payload_map) { { first: payload_bytes, second: payload_nil } }

    it 'converts and encodes' do
      expect(subject.to_payload_map(first: 'test-payload'.b, second: nil)).to eq(payload_map)
      expect(codec).to have_received(:encode).twice
    end
  end
end
