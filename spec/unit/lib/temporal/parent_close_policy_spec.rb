require 'temporal/parent_close_policy'

describe Temporal::ParentClosePolicy do
  describe '#validate!' do
    subject { described_class.new(param) }

    context 'with valid param' do
      %i[abandon terminate request_cancel].each do |policy|
        context "with #{policy}" do
          let(:param) { policy }

          it 'does not raise' do
            expect { subject.validate! }.not_to raise_error
          end
        end
      end
    end

    context 'with invalid param' do
      let(:param) { :coinbase }

      it 'does not raise' do
        expect { subject.validate! }.to raise_error(described_class::InvalidParentClosePolicy)
      end
    end
  end
end
