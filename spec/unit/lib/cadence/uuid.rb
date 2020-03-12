require 'cadence/uuid'

describe Cadence::UUID do
  describe '.v5' do
    let(:root) { 'f71fc57b-5a66-4363-96ea-b27061dd8edf' }
    let(:name) { 'cadence' }
    let(:result) { '415e3a4a-4a01-5c70-8616-dcd9da8ec02c' }

    it 'generates predictable UUID v5' do
      expect(described_class.v5(root, name)).to eq(result)
    end
  end
end
