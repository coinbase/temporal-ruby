require 'temporal/client/converter/legacy'

describe Temporal::Client::Converter::Legacy do
  subject { described_class.new }

  describe 'to_payloads' do
    it 'writes a single payload' do
      payloads = subject.to_payloads(1, 2)

      expect(payloads.payloads.length).to eq(1)
    end

    it 'sets legacy encoding metadata' do
      payloads = subject.to_payloads(1, 2)
      payload = payloads.payloads.first

      expect(payload.metadata['encoding']).to eq('json/legacy')
    end

    it 'round trip' do
      result = subject.from_payloads(subject.to_payloads(1, 2))

      expect(result).to eq([1, 2])
    end
  end
end
