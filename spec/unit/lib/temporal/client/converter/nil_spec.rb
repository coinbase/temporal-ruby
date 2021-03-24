require 'temporal/client/converter/nil'

describe Temporal::Client::Converter::Nil do
  subject { described_class.new }

  it 'encodes a null payload' do
    payload = Temporal::Api::Common::V1::Payload.new(
      metadata: { 'encoding' => described_class::ENCODING }
    )

    expect(subject.to_payload(nil)).to eq(payload)
  end

  it 'decodes a null payload' do
    payload = Temporal::Api::Common::V1::Payload.new(
      metadata: { 'encoding' => described_class::ENCODING }
    )

    expect(subject.from_payload(payload)).to eq(nil)
  end
end
