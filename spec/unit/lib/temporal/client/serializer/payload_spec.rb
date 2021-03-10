require 'temporal/client/serializer/payload'

describe Temporal::Client::Serializer::Payload do
  let(:hash) { { 'one' => 'one', two: :two, ':three' => '☻' } }

  describe 'round trip' do
    it 'safely handles non-ASCII encodable UTF characters' do
      expect(
        described_class.from_proto(described_class.new(hash).to_proto)
      ).to eq(hash)
    end
  end
end
