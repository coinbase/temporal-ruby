require 'cadence/json'

describe Cadence::JSON do
  let(:hash) { { 'one' => 'one', two: :two, ':three' => ':three' } }
  let(:json) { '{"one":"one",":two":":two","\u003athree":"\u003athree"}' }

  describe '.serialize' do
    it 'generates JSON string' do
      expect(described_class.serialize(hash)).to eq(json)
    end
  end

  describe '.deserialize' do
    it 'parses JSON string' do
      expect(described_class.deserialize(json)).to eq(hash)
    end

    it 'parses empty string to nil' do
      expect(described_class.deserialize('')).to eq(nil)
    end

    it 'parses nil' do
      expect(described_class.deserialize(nil)).to eq(nil)
    end
  end
end
