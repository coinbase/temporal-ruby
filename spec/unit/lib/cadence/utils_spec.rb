require 'cadence/utils'

describe Cadence::Utils do
  let(:time) { Time.new(2020, 4, 28, 15, 23, 16) }

  describe '.time_from_nanos' do
    subject { described_class.time_from_nanos(timestamp) }
    let(:timestamp) { 1588083796538941000 }

    it 'returns time' do
      expect(subject.to_i).to eq(time.to_i)
      expect(subject.nsec).to eq(timestamp % described_class::NANO)
    end
  end

  describe '.time_to_nanos' do
    subject { described_class.time_to_nanos(time) }

    it 'returns nanosecond timestamp' do
      expect(subject).to eq(1588083796000000000)
    end
  end
end
