require 'temporal/client'

describe Temporal::Client do
  describe 'converter' do
    let(:hash) { { 'one' => 'one', two: :two, ':three' => '☻' } }
    subject { described_class.converter }

    describe 'round trip' do
      it 'safely handles non-ASCII encodable UTF characters' do
        expect(subject.from_payload(subject.to_payload(hash))).to eq(hash)
      end
    end
  end
end
