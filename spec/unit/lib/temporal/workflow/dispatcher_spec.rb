require 'temporal/workflow/dispatcher'
require 'temporal/workflow/history/event_target'

describe Temporal::Workflow::Dispatcher do
  let(:target) { Temporal::Workflow::History::EventTarget.new(1, Temporal::Workflow::History::EventTarget::ACTIVITY_TYPE) }
  let(:other_target) { Temporal::Workflow::History::EventTarget.new(2, Temporal::Workflow::History::EventTarget::TIMER_TYPE) }

  describe '#register_handler' do
    let(:block) { -> { 'handler body' } }
    let(:event_name) { 'signaled' }
    let(:dispatcher) { subject.register_handler(target, event_name, handler_name: handler_name, &block) }
    let(:handlers) { dispatcher.send(:handlers) }

    context 'with default handler_name' do
      let(:handler_name) { nil }

      it 'stores the target' do
        expect(handlers.key?(target)).to be true
      end

      it 'stores the target and handler once' do
        expect(handlers[target]).to be_kind_of(Array)
        expect(handlers[target].count).to eq 1
      end

      it 'associates the event name with the target' do
        event = handlers[target].first
        expect(event.event_name).to eq(event_name)
      end

      it 'associates the handler with the target' do
        event = handlers[target].first
        expect(event.handler).to eq(block)
      end

      it 'defaults to nil for handler_name' do
        event = handlers[target].first
        expect(event.handler_name).to be nil
      end
    end

    context 'with a specific handler_name' do
      let(:handler_name) { 'specific name' }

      it 'stores the target' do
        expect(handlers.key?(target)).to be true
      end

      it 'stores the target and handler once' do
        expect(handlers[target]).to be_kind_of(Array)
        expect(handlers[target].count).to eq 1
      end

      it 'associates the event name with the target' do
        event = handlers[target].first
        expect(event.event_name).to eq(event_name)
      end

      it 'associates the handler with the target' do
        event = handlers[target].first
        expect(event.handler).to eq(block)
      end

      it 'associates the handler name with the target' do
        event = handlers[target].first
        expect(event.handler_name).to eq(handler_name)
      end

      it 'raises an ArgumentError when named handler is registered twice' do
        subject.register_handler(target, event_name, handler_name: handler_name, &block)

        # second call!
        expect do
          subject.register_handler(target, event_name, handler_name: handler_name, &block)
        end.to raise_error(described_class::DuplicateNamedHandlerRegistrationError, "Duplicate registration for handler_name #{handler_name}")
      end
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
      before do
        allow(handler_6).to receive(:call)

        subject.register_handler(described_class::TARGET_WILDCARD, described_class::WILDCARD, &handler_6)
      end

      it 'calls the handler' do
        subject.dispatch(target, 'completed')

        # Target handlers still invoked
        expect(handler_1).to have_received(:call).ordered
        expect(handler_4).to have_received(:call).ordered
        expect(handler_6).to have_received(:call).ordered
      end

      it 'TARGET_WILDCARD can be compared to an EventTarget object' do
        expect(target.eql?(described_class::TARGET_WILDCARD)).to be(false)
      end
    end

    context 'with a named handler' do
      let(:handler_7) { -> { 'seventh block' } }
      let(:handler_name) { 'specific name' }
      before do
        allow(handler_7).to receive(:call)

        subject.register_handler(target, 'completed', handler_name: handler_name, &handler_7)
      end

      it 'calls ONLY the named handler' do
        subject.dispatch(target, 'completed', handler_name: handler_name)

        expect(handler_7).to have_received(:call)

        expect(handler_1).not_to have_received(:call)
        expect(handler_2).not_to have_received(:call)
        expect(handler_3).not_to have_received(:call)
        expect(handler_4).not_to have_received(:call)
      end
    end
  end
end
