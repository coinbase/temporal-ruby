require 'cadence/middleware/chain'
require 'cadence/middleware/entry'

describe Cadence::Middleware::Chain do
  class TestChainMiddleware
    def call(_)
      yield

      # expect this to be ignored
      return 'middleware result'
    end
  end

  describe '#invoke' do
    subject { described_class.new(middleware) }
    let(:metadata) { instance_double('Cadence::Activity::Metadata') }
    let(:block) { -> { 'result' } }

    context 'with middleware' do
      let(:middleware) do
        [
          Cadence::Middleware::Entry.new(TestChainMiddleware),
          Cadence::Middleware::Entry.new(TestChainMiddleware)
        ]
      end
      let(:middleware_1) { TestChainMiddleware.new }
      let(:middleware_2) { TestChainMiddleware.new }

      before do
        allow(TestChainMiddleware).to receive(:new).and_return(middleware_1, middleware_2)

        allow(middleware_1).to receive(:call).and_call_original
        allow(middleware_2).to receive(:call).and_call_original
      end

      it 'calls each middleware' do
        subject.invoke(metadata, &block)

        expect(middleware_1).to have_received(:call).with(metadata).ordered
        expect(middleware_2).to have_received(:call).with(metadata).ordered
      end

      it 'calls passed in block' do
        expect { |b| subject.invoke(metadata, &b) }.to yield_control
      end

      it 'returns the result of the passed block' do
        expect(subject.invoke(metadata, &block)).to eq('result')
      end
    end

    context 'without middleware' do
      let(:middleware) { [] }

      it 'calls passed in block' do
        expect { |b| subject.invoke(metadata, &b) }.to yield_control
      end

      it 'returns the result of the passed block' do
        expect(subject.invoke(metadata, &block)).to eq('result')
      end
    end
  end
end
