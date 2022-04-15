require 'temporal/workflow/query_registry'

describe Temporal::Workflow::QueryRegistry do
  subject { described_class.new }

  describe '#register' do
    let(:handler) { Proc.new {} }

    it 'registers a query handler' do
      subject.register('test-query', &handler)

      expect(subject.send(:handlers)['test-query']).to eq(handler)
    end

    context 'when query handler is already registered' do
      let(:handler_2) { Proc.new {} }

      before { subject.register('test-query', &handler) }

      it 'warns' do
        allow(subject).to receive(:warn)

        subject.register('test-query', &handler_2)

        expect(subject)
          .to have_received(:warn)
          .with('[NOTICE] Overwriting a query handler for test-query')
      end

      it 're-registers a query handler' do
        subject.register('test-query', &handler_2)

        expect(subject.send(:handlers)['test-query']).to eq(handler_2)
      end
    end
  end

  describe '#handle' do
    context 'when a query handler has been registered' do
      let(:handler) { Proc.new { 42 } }

      before { subject.register('test-query', &handler) }

      it 'runs the handler and returns the result' do
        expect(subject.handle('test-query')).to eq(42)
      end
    end

    context 'when a query handler has been registered with args' do
      let(:handler) { Proc.new { |arg_1, arg_2| arg_1 + arg_2 } }

      before { subject.register('test-query', &handler) }

      it 'runs the handler and returns the result' do
        expect(subject.handle('test-query', [3, 5])).to eq(8)
      end
    end

    context 'when a query handler has not been registered' do
      it 'raises' do
        expect do
          subject.handle('test-query')
        end.to raise_error(Temporal::QueryFailed, 'Workflow did not register a handler for test-query')
      end
    end
  end
end
