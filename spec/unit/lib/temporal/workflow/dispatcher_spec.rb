require 'temporal/workflow/dispatcher'

describe Temporal::Workflow::Dispatcher do
  describe '#register_handler' do
    it 'stores a given handler against the target' do
      block = -> { 'handler body' }

      subject.register_handler('target', 'signaled', &block)

      expect(subject.send(:handlers)).to include('target' => [['signaled', block]])
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

      subject.register_handler('target', 'completed', &handler_1)
      subject.register_handler('other_target', 'completed', &handler_2)
      subject.register_handler('target', 'failed', &handler_3)
      subject.register_handler('target', 'completed', &handler_4)
    end

    it 'calls all matching handlers in the original order' do
      subject.dispatch('target', 'completed')

      expect(handler_1).to have_received(:call).ordered
      expect(handler_4).to have_received(:call).ordered

      expect(handler_2).not_to have_received(:call)
      expect(handler_3).not_to have_received(:call)
    end

    it 'passes given arguments to the handlers' do
      subject.dispatch('target', 'failed', ['TIME_OUT', 'Exceeded execution time'])

      expect(handler_3).to have_received(:call).with('TIME_OUT', 'Exceeded execution time')

      expect(handler_1).not_to have_received(:call)
      expect(handler_2).not_to have_received(:call)
      expect(handler_4).not_to have_received(:call)
    end

    context 'with WILDCARD handler' do
      let(:handler_5) { -> { 'fifth block' } }

      before do
        allow(handler_5).to receive(:call)

        subject.register_handler('target', described_class::WILDCARD, &handler_5)
      end

      it 'calls the handler' do
        subject.dispatch('target', 'completed')

        expect(handler_5).to have_received(:call)
      end

    end
  end
end
