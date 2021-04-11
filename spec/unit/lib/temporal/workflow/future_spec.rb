require 'temporal/workflow/future'

describe Temporal::Workflow::Future do
  let(:workflow_context) { instance_double('Temporal::Workflow::Context') }
  let(:target) { 'dummy_target' }
  let(:cancelation_id) { 'cancelation_id_1' }

  subject { described_class.new(target, workflow_context, cancelation_id: cancelation_id) }

  describe '#set' do
    it 'failed?, ready?, finished? correct before and after' do
      expect(subject.failed?).to be false
      expect(subject.ready?).to be false
      expect(subject.finished?).to be false

      subject.set('success')
      expect(subject.failed?).to be false
      expect(subject.ready?).to be true
      expect(subject.finished?).to be true
    end
  end

  describe '#fail' do
    it 'failed?, ready?, finished? correct before and after' do
      expect(subject.failed?).to be false
      expect(subject.ready?).to be false
      expect(subject.finished?).to be false

      subject.fail('failed')
      expect(subject.failed?).to be true
      expect(subject.ready?).to be false
      expect(subject.finished?).to be true
    end
  end

  describe '#get' do
    it 'result if set' do
      result = 'success'
      subject.set(result)
      expect(subject.get).to be result
    end

    it 'exception if fail' do
      exception = StandardError.new('failed')
      subject.fail(exception)
      expect(subject.get).to be exception
    end

    it 'calls context.wait_for if not finished' do
      allow(workflow_context).to receive(:wait_for).with(subject)
      subject.get
    end
  end

  describe '#wait' do
    it 'does not wait if already done' do
      subject.set('success')
      subject.wait
    end

    it 'calls context.wait_for if not already done' do
      allow(workflow_context).to receive(:wait_for).with(subject)
      subject.wait
    end
  end

  describe '#cancel' do
    it 'does nothing, returns false if already finished' do
      subject.set('already done')
      expect(subject.cancel).to be false
    end

    it 'calls context if still pending and cancel succeeds' do
      allow(workflow_context).to receive(:cancel).with(target, cancelation_id).and_return(true)
      expect(subject.cancel).to be true
    end

    it 'calls context if still pending and cancel fails' do
      allow(workflow_context).to receive(:cancel).with(target, cancelation_id).and_return(false)
      expect(subject.cancel).to be false
    end
  end

  describe '#done' do
    it 'calls back immediately when already done' do
      expected_result = 'success'
      subject.set(expected_result)

      called_with_result = nil
      subject.done do |result|
        called_with_result = result
      end

      expect(called_with_result).to be expected_result
    end

    it 'delays callback until done' do
      called_with_result = nil
      subject.done do |result|
        called_with_result = result
      end

      expect(called_with_result).to be nil

      expected_result = 'success'
      subject.set(expected_result)

      expect(called_with_result).to be nil
      expect(subject.success_callbacks.length). to be 1

      subject.success_callbacks[0].call(expected_result)
      expect(called_with_result).to be expected_result
    end

    it 'does not call on failure' do
      expected_exception = StandardError.new('failed')
      subject.fail(expected_exception)

      called_with_result = nil
      subject.done do |result|
        called_with_result = result
      end

      expect(called_with_result).to be nil
    end
  end

  describe '#failed' do
    it 'calls back immediately when already failed' do
      expected_exception = StandardError.new('failure')
      subject.fail(expected_exception)

      called_with_exception = nil
      subject.failed do |exception|
        called_with_exception = exception
      end

      expect(called_with_exception).to be expected_exception
    end

    it 'delays callback until done' do
      called_with_exception = nil
      subject.failed do |exception|
        called_with_exception = exception
      end

      expect(called_with_exception).to be nil

      expected_exception = StandardError.new('failure')
      subject.fail(expected_exception)

      expect(called_with_exception).to be nil
      expect(subject.failure_callbacks.length). to be 1

      subject.failure_callbacks[0].call(expected_exception)
      expect(called_with_exception).to be expected_exception
    end

    it 'does not call on success' do
      expected_result = 'success'
      subject.set(expected_result)

      called_with_exception = nil
      subject.failed do |exception|
        called_with_exception = exception
      end

      expect(called_with_exception).to be nil
    end
  end
end
