require 'temporal/connection/serializer/priority'

describe Temporal::Connection::Serializer::Priority do
  subject { described_class.new(priority) }

  describe '#to_proto' do
    context 'when priority is nil' do
      let(:priority) { nil }

      it 'returns nil' do
        expect(subject.to_proto).to be_nil
      end
    end

    context 'when priority has all fields' do
      let(:priority) { Temporal::Priority.new(priority_key: 10, fairness_key: 'production', fairness_weight: 0.8) }

      it 'creates correct proto object' do
        proto = subject.to_proto
        
        expect(proto).to be_an_instance_of(Temporalio::Api::Common::V1::Priority)
        expect(proto.priority_key).to eq(10)
        expect(proto.fairness_key).to eq('production')
        expect(proto.fairness_weight).to eq(0.8)
      end
    end

    context 'when priority has only priority_key' do
      let(:priority) { Temporal::Priority.new(priority_key: 5, fairness_key: nil) }

      it 'creates proto object with only priority_key' do
        proto = subject.to_proto
        
        expect(proto).to be_an_instance_of(Temporalio::Api::Common::V1::Priority)
        expect(proto.priority_key).to eq(5)
        expect(proto.fairness_key).to eq('')
      end
    end

    context 'when priority has only fairness_key' do
      let(:priority) { Temporal::Priority.new(priority_key: nil, fairness_key: 'staging', fairness_weight: nil) }

      it 'creates proto object with only fairness_key' do
        proto = subject.to_proto
        
        expect(proto).to be_an_instance_of(Temporalio::Api::Common::V1::Priority)
        expect(proto.priority_key).to eq(0)
        expect(proto.fairness_key).to eq('staging')
        expect(proto.fairness_weight).to eq(0.0)
      end
    end

    context 'when priority has only fairness_weight' do
      let(:priority) { Temporal::Priority.new(priority_key: nil, fairness_key: nil, fairness_weight: 0.5) }

      it 'creates proto object with only fairness_weight' do
        proto = subject.to_proto
        
        expect(proto).to be_an_instance_of(Temporalio::Api::Common::V1::Priority)
        expect(proto.priority_key).to eq(0)
        expect(proto.fairness_key).to eq('')
        expect(proto.fairness_weight).to eq(0.5)
      end
    end

    context 'when priority has no keys' do
      let(:priority) { Temporal::Priority.new(priority_key: nil, fairness_key: nil, fairness_weight: nil) }

      it 'creates empty proto object' do
        proto = subject.to_proto
        
        expect(proto).to be_an_instance_of(Temporalio::Api::Common::V1::Priority)
        expect(proto.priority_key).to eq(0)
        expect(proto.fairness_key).to eq('')
        expect(proto.fairness_weight).to eq(0.0)
      end
    end
  end
end 