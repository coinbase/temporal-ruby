require 'temporal/retry_policy'

describe Temporal::RetryPolicy do
  describe '#validate!' do
    subject { described_class.new(attributes) }

    let(:valid_attributes) do
      {
        initial_interval: 1,
        backoff_coefficient: 1.5,
        maximum_interval: 5,
        maximum_attempts: 3,
        non_retryable_error_types: nil
      }
    end

    shared_examples 'error' do |message|
      it 'raises InvalidRetryPolicy error' do
        expect { subject.validate! }.to raise_error(described_class::InvalidRetryPolicy, message)
      end
    end

    context 'with valid attributes' do
      let(:attributes) { valid_attributes }

      it 'does not raise' do
        expect { subject.validate! }.not_to raise_error
      end
    end

    context 'with invalid attributes' do
      context 'with missing :interval' do
        let(:attributes) { valid_attributes.tap { |h| h.delete(:initial_interval) } }

        include_examples 'error', 'initial_interval must be set'
      end

      %i[initial_interval maximum_interval].each do |attr|
        context "with #{attr} set to a float" do
          let(:attributes) { valid_attributes.tap { |h| h[attr] = 1.5 } }

          include_examples 'error', 'All intervals must be specified in whole seconds'
        end

        context "with #{attr} set to zero" do
          let(:attributes) { valid_attributes.tap { |h| h[attr] = 0 } }

          include_examples 'error', 'All intervals must be greater than 0'
        end

        context "with #{attr} set to negative value" do
          let(:attributes) { valid_attributes.tap { |h| h[attr] = -2 } }

          include_examples 'error', 'All intervals must be greater than 0'
        end
      end

      context "with maximum_attempts set to negative value" do
        let(:attributes) { valid_attributes.tap { |h| h[:maximum_attempts] = -2 } }

        include_examples 'error', 'maximum_attempts must be greater than or equal to 0'
      end
    end
  end
end
