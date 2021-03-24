require 'temporal/client/converter/base'

describe Temporal::Client::Converter do
  subject { Temporal::Client::Converter::Base.new }

  before do
    allow(subject).to receive(:to_payload)
    allow(subject).to receive(:from_payload)
  end

  describe 'round trip' do
    it 'encodes a single array argument as one payload' do
      input = [1]

      payloads = subject.to_payloads(input)

      expect(subject).to have_received(:to_payload).once
      expect(payloads.payloads.length).to eql(1)
    end

    it 'encodes multiple arguments as separate payloads' do
      input1 = [1]
      input2 = [2]

      payloads = subject.to_payloads(input1, input2)

      expect(subject).to have_received(:to_payload).exactly(2).times
      expect(payloads.payloads.length).to eql(2)
    end
  end
end
