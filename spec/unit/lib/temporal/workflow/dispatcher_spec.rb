require 'temporal/workflow/dispatcher'
require 'temporal/workflow/history/event_target'

describe Temporal::Workflow::Dispatcher do
  let(:target) { Temporal::Workflow::History::EventTarget.new(1, Temporal::Workflow::History::EventTarget::ACTIVITY_TYPE) }
  let(:other_target) { Temporal::Workflow::History::EventTarget.new(2, Temporal::Workflow::History::EventTarget::TIMER_TYPE) }

  describe '#register_handler' do
    it 'stores a given handler against the target' do
      block = -> { 'handler body' }

      subject.register_handler(target, 'signaled', &block)

      expect(subject.send(:handlers)).to include(target => { 1 => ['signaled', block] })
    end

    it 'removes a given handler against the target' do
      block1 = -> { 'handler body' }
      block2 = -> { 'other handler body' }
      block3 = -> { 'yet another handler body' }

      handle1 = subject.register_handler(target, 'signaled', &block1)
      subject.register_handler(target, 'signaled', &block2)
      subject.register_handler(other_target, 'signaled', &block3)

      expect(subject.send(:handlers)).to include(target => { 1 => ['signaled', block1], 2 => ['signaled', block2] })
      expect(subject.send(:handlers)).to include(other_target => { 3 => ['signaled', block3]})

      handle1.unregister
      expect(subject.send(:handlers)).to include(target => { 2 => ['signaled', block2] })
      expect(subject.send(:handlers)).to include(other_target => { 3 => ['signaled', block3] })
    end
  end

  describe '#dispatch' do
    let(:handler_1) { -> { 'first block' } }
    let(:handler_2) { -> { 'second block' } }
    let(:handler_3) { -> (arg_1, arg_2) { 'third block' } }
    let(:handler_4) { -> { 'fourth block' } }

    before do
      [handler_1, handler_2, handler_3, handler_4].each do |handler|
        allow(handler).to receive(:call)
      end

      subject.register_handler(target, 'completed', &handler_1)
      subject.register_handler(other_target, 'completed', &handler_2)
      subject.register_handler(target, 'failed', &handler_3)
      subject.register_handler(target, 'completed', &handler_4)
    end

    it 'calls all matching handlers in the original order' do
      subject.dispatch(target, 'completed')

      expect(handler_1).to have_received(:call).ordered
      expect(handler_4).to have_received(:call).ordered

      expect(handler_2).not_to have_received(:call)
      expect(handler_3).not_to have_received(:call)
    end

    it 'passes given arguments to the handlers' do
      subject.dispatch(target, 'failed', ['TIME_OUT', 'Exceeded execution time'])

      expect(handler_3).to have_received(:call).with('TIME_OUT', 'Exceeded execution time')

      expect(handler_1).not_to have_received(:call)
      expect(handler_2).not_to have_received(:call)
      expect(handler_4).not_to have_received(:call)
    end

    context 'with WILDCARD handler' do
      let(:handler_5) { -> { 'fifth block' } }

      before do
        allow(handler_5).to receive(:call)

        subject.register_handler(target, described_class::WILDCARD, &handler_5)
      end

      it 'calls the handler' do
        subject.dispatch(target, 'completed')

        expect(handler_5).to have_received(:call)
      end
    end

    context 'with TARGET_WILDCARD target handler' do
      let(:handler_6) { -> { 'sixth block' } }
      let(:handler_7) { -> { 'seventh block' } }
      before do
        allow(handler_6).to receive(:call)
        allow(handler_7).to receive(:call)

        subject.register_handler(described_class::TARGET_WILDCARD, described_class::WILDCARD, &handler_6)
        subject.register_handler(target, 'completed', &handler_7)
      end

      it 'calls the handler' do
        subject.dispatch(target, 'completed')

        # Target handlers still invoked
        expect(handler_1).to have_received(:call).ordered
        expect(handler_4).to have_received(:call).ordered
        expect(handler_6).to have_received(:call).ordered
        expect(handler_7).to have_received(:call).ordered
      end

      it 'TARGET_WILDCARD can be compared to an EventTarget object' do
        expect(target.eql?(described_class::TARGET_WILDCARD)).to be(false)
      end
    end
  end
end
