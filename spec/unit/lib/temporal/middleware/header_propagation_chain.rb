require 'temporal/middleware/header_propagator_chain'
require 'temporal/middleware/entry'

describe Temporal::Middleware::HeaderPropagatorChain do
  class TestHeaderPropagator
    attr_reader :id
    
    def initialize(id)
      @id = id
    end

    def inject!(header)
      header['first'] = id unless header.has_key? :first
      header[id] = id
    end
  end

  describe '#inject' do
    subject { described_class.new(propagators) }
    let(:headers) { { 'test' => 'header' } }

    context 'with propagators' do
      let(:propagators) do
        [
          propagator_1,
          propagator_2,
        ]
      end
      let(:propagator_1) { Temporal::Middleware::Entry.new(TestHeaderPropagator, '1') }
      let(:propagator_2) { Temporal::Middleware::Entry.new(TestHeaderPropagator, '2') }

      it 'calls each propagator in order' do
        expected = {
          'test' => 'header',
          'first' => '1',
          '1' => '1',
          '2' => '2',
        }
        expect(subject.inject(headers)).to eq(expected)
      end
    end

    context 'without propagators' do
      let(:propagators) { [] }

      it 'returns the result of the passed block' do
        expect(subject.inject(headers)).to eq(headers)
      end
    end
  end
end
