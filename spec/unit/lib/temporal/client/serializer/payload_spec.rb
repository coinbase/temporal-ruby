require 'temporal/client/serializer/payload'

describe Temporal::Client::Serializer::Payload do
  describe 'round trip' do
    context 'when object is a hash' do
      let(:hash) { { 'one' => 'one', two: :two, ':three' => 3 } }

      it 'converts to and from proto' do
        expect(
          described_class.from_proto(described_class.new(hash).to_proto)
        ).to eq(hash)
      end
    end

    context 'when object is an array' do
      let(:hash) { %w[one two] }

      it 'converts to and from proto' do
        expect(
          described_class.from_proto(described_class.new(hash).to_proto)
        ).to eq(hash)
      end
    end

    context 'when object has non-ASCII chars' do
      let(:hash) { { 'three' => '☻' } }

      it 'safely handles non-ASCII encodable UTF characters' do
        expect(
          described_class.from_proto(described_class.new(hash).to_proto)
        ).to eq(hash)
      end
    end
  end

  describe 'array handling' do
    it 'creates multiple payloads' do
      object = %w[one two]

      proto = described_class.new(object).to_proto

      expect(proto.payloads.count).to eq(object.count)
    end
  end
end
