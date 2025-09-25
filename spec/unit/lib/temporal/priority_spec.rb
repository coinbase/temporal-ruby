require 'temporal/priority'

describe Temporal::Priority do
  describe '#validate!' do
    subject { described_class.new(attributes) }

    let(:valid_attributes) do
      {
        priority_key: 10,
        fairness_key: 'test-fairness',
        fairness_weight: 0.75
      }
    end

    let(:empty_attributes) do
      {
        priority_key: nil,
        fairness_key: nil,
        fairness_weight: nil
      }
    end

    let(:partial_attributes) do
      {
        priority_key: 5,
        fairness_key: nil,
        fairness_weight: nil
      }
    end

    shared_examples 'error' do |message|
      it 'raises InvalidPriority error' do
        expect { subject.validate! }.to raise_error(described_class::InvalidPriority, message)
      end
    end

    context 'with valid attributes' do
      let(:attributes) { valid_attributes }

      it 'does not raise' do
        expect { subject.validate! }.not_to raise_error
      end

      it 'has correct values' do
        expect(subject.priority_key).to eq(10)
        expect(subject.fairness_key).to eq('test-fairness')
        expect(subject.fairness_weight).to eq(0.75)
      end
    end

    context 'with empty attributes' do
      let(:attributes) { empty_attributes }

      it 'does not raise' do
        expect { subject.validate! }.not_to raise_error
      end
    end

    context 'with partial attributes' do
      let(:attributes) { partial_attributes }

      it 'does not raise' do
        expect { subject.validate! }.not_to raise_error
      end
    end

    context 'with invalid priority_key' do
      context 'when priority_key is a string' do
        let(:attributes) { { priority_key: 'invalid', fairness_key: 'test' } }
        include_examples 'error', 'PriorityKey must be a number'
      end

      context 'when priority_key is an array' do
        let(:attributes) { { priority_key: [1, 2, 3], fairness_key: 'test' } }
        include_examples 'error', 'PriorityKey must be a number'
      end
    end

    context 'with invalid fairness_key' do
      context 'when fairness_key is a number' do
        let(:attributes) { { priority_key: 10, fairness_key: 123 } }
        include_examples 'error', 'FairnessKey must be a string'
      end

      context 'when fairness_key is a symbol' do
        let(:attributes) { { priority_key: 10, fairness_key: :test } }
        include_examples 'error', 'FairnessKey must be a string'
      end
    end

    context 'with invalid fairness_weight' do
      context 'when fairness_weight is a string' do
        let(:attributes) { { priority_key: 10, fairness_key: 'test', fairness_weight: 'invalid' } }
        include_examples 'error', 'FairnessWeight must be a number'
      end

      context 'when fairness_weight is an array' do
        let(:attributes) { { priority_key: 10, fairness_key: 'test', fairness_weight: [1, 2, 3] } }
        include_examples 'error', 'FairnessWeight must be a number'
      end
    end
  end

  describe '#to_hash' do
    subject { described_class.new(attributes).to_hash }

    context 'with all fields' do
      let(:attributes) { { priority_key: 15, fairness_key: 'production', fairness_weight: 0.8 } }

      it 'returns hash with all fields' do
        expect(subject).to eq({
          'PriorityKey' => 15,
          'FairnessKey' => 'production',
          'FairnessWeight' => 0.8
        })
      end
    end

    context 'with only priority_key' do
      let(:attributes) { { priority_key: 5, fairness_key: nil } }

      it 'returns hash with only PriorityKey' do
        expect(subject).to eq({
          'PriorityKey' => 5
        })
      end
    end

    context 'with only fairness_key' do
      let(:attributes) { { priority_key: nil, fairness_key: 'staging', fairness_weight: nil } }

      it 'returns hash with only FairnessKey' do
        expect(subject).to eq({
          'FairnessKey' => 'staging'
        })
      end
    end

    context 'with only fairness_weight' do
      let(:attributes) { { priority_key: nil, fairness_key: nil, fairness_weight: 0.5 } }

      it 'returns hash with only FairnessWeight' do
        expect(subject).to eq({
          'FairnessWeight' => 0.5
        })
      end
    end

    context 'with no keys' do
      let(:attributes) { { priority_key: nil, fairness_key: nil, fairness_weight: nil } }

      it 'returns empty hash' do
        expect(subject).to eq({})
      end
    end
  end
end 