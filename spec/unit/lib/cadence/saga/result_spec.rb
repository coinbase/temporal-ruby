require 'cadence/saga/result'

describe Cadence::Saga::Result do
  context 'with completed result' do
    let(:result) { described_class.new(true) }

    describe '#completed?' do
      subject { result.completed? }

      it { is_expected.to eq(true) }
    end

    describe '#compensated?' do
      subject { result.compensated? }

      it { is_expected.to eq(false) }
    end

    describe '#rollback_reason' do
      subject { result.rollback_reason }

      it { is_expected.to eq(nil) }
    end
  end

  context 'with compensated result' do
    let(:result) { described_class.new(false, 'something went wrong') }

    describe '#completed?' do
      subject { result.completed? }

      it { is_expected.to eq(false) }
    end

    describe '#compensated?' do
      subject { result.compensated? }

      it { is_expected.to eq(true) }
    end

    describe '#rollback_reason' do
      subject { result.rollback_reason }

      it { is_expected.to eq('something went wrong') }
    end

  end
end
