require 'temporal/client/converter/json'

describe Temporal::Client::Converter::JSON do
  subject { described_class.new }

  describe 'round trip' do
    it 'safely handles non-ASCII encodable UTF characters' do
      input = { 'one' => 'one', two: :two, ':three' => '☻' }

      expect(subject.from_payload(subject.to_payload(input))).to eq(input)
    end
  end
end
