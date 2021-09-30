require 'temporal/parent_close_policy'
require 'temporal/connection/serializer/parent_close_policy'

describe Temporal::Connection::Serializer::ParentClosePolicy do
  describe 'to_proto' do
    let(:terminate_policy) { Temporal::ParentClosePolicy.new(:terminate) }
    let(:abandon_policy) { Temporal::ParentClosePolicy.new(:abandon) }
    let(:request_cancel_policy) { Temporal::ParentClosePolicy.new(:request_cancel) }

    it 'converts to proto' do
      expect do
        described_class.new(terminate_policy).to_proto
      end.not_to raise_error

      expect do
        described_class.new(abandon_policy).to_proto
      end.not_to raise_error

      expect do
        described_class.new(request_cancel_policy).to_proto
      end.not_to raise_error
    end
  end
end
