require 'cadence/retry_policy'

describe Cadence::RetryPolicy do
  describe '#validate!' do
    subject { described_class.new(attributes) }

    let(:valid_attributes) do
      {
        interval: 1,
        backoff: 1.5,
        max_interval: 5,
        max_attempts: 3,
        expiration_interval: nil,
        non_retriable_errors: nil
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
        let(:attributes) { valid_attributes.tap { |h| h.delete(:interval) } }

        include_examples 'error', 'interval and backoff must be set'
      end

      context 'with missing :backoff' do
        let(:attributes) { valid_attributes.tap { |h| h.delete(:backoff) } }

        include_examples 'error', 'interval and backoff must be set'
      end

      context 'with :max_attempts and :expiration_interval missing' do
        let(:attributes) do
          valid_attributes.tap do |h|
            h.delete(:max_attempts)
            h.delete(:expiration_interval)
          end
        end

        include_examples 'error', 'max_attempts or expiration_interval must be set'
      end

      %i[interval max_interval expiration_interval].each do |attr|
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
    end
  end
end
