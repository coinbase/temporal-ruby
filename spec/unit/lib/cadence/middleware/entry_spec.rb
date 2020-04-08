require 'cadence/middleware/entry'

describe Cadence::Middleware::Entry do
  class TestEntryMiddleware
    def call(_); end
  end

  class TestEntryMiddlewareWithArguments
    def initialize(arg_1, arg2); end
    def call(_); end
  end

  describe '#init_middleware' do
    subject { described_class.new(klass, args) }
    let(:klass) { TestEntryMiddleware }
    let(:args) { [] }

    before { allow(klass).to receive(:new).and_call_original }

    it 'returns an instance of the middlware class' do
      expect(subject.init_middleware).to be_an_instance_of(klass)
      expect(klass).to have_received(:new)
    end

    context 'with arguments' do
      let(:klass) { TestEntryMiddlewareWithArguments }
      let(:args) { ['1', 2] }

      it 'returns an instance of the middlware class' do
        expect(subject.init_middleware).to be_an_instance_of(klass)
        expect(klass).to have_received(:new).with('1', 2)
      end
    end
  end
end
