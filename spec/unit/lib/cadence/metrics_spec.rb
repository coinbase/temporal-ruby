require 'cadence/metrics'

describe Cadence::Metrics do
  subject { described_class.new(adapter) }
  let(:adapter) { instance_double('MetricsAdapter') }
  let(:logger) { instance_double('Logger') }
  let(:key) { 'cadence.metric' }
  let(:value) { rand(100) }
  let(:tags) { { foo: 'bar' } }

  before do
    allow(adapter).to receive(:count)
    allow(adapter).to receive(:gauge)
    allow(adapter).to receive(:timing)

    allow(Cadence).to receive(:logger).and_return(logger)
    allow(logger).to receive(:error)
  end

  describe '#increment' do
    it 'calls adapter' do
      subject.increment(key)

      expect(adapter).to have_received(:count).with(key, 1, {})
    end

    it 'calls adapter with tags' do
      subject.increment(key, tags)

      expect(adapter).to have_received(:count).with(key, 1, tags)
    end

    context 'when adapter fails' do
      before { allow(adapter).to receive(:count).and_raise(StandardError, 'test') }

      it 'logs' do
        subject.increment(key)

        expect(logger)
          .to have_received(:error)
          .with("Adapter failed to send count metrics for cadence.metric: #<StandardError: test>")
      end
    end
  end

  describe '#decrement' do
    it 'calls adapter' do
      subject.decrement(key)

      expect(adapter).to have_received(:count).with(key, -1, {})
    end

    it 'calls adapter with tags' do
      subject.decrement(key, tags)

      expect(adapter).to have_received(:count).with(key, -1, tags)
    end

    context 'when adapter fails' do
      before { allow(adapter).to receive(:count).and_raise(StandardError, 'test') }

      it 'logs' do
        subject.decrement(key)

        expect(logger)
          .to have_received(:error)
          .with("Adapter failed to send count metrics for cadence.metric: #<StandardError: test>")
      end
    end
  end

  describe '#count' do
    it 'calls adapter' do
      subject.count(key, value)

      expect(adapter).to have_received(:count).with(key, value, {})
    end

    it 'calls adapter with tags' do
      subject.count(key, value, tags)

      expect(adapter).to have_received(:count).with(key, value, tags)
    end

    context 'when adapter fails' do
      before { allow(adapter).to receive(:count).and_raise(StandardError, 'test') }

      it 'logs' do
        subject.count(key, value)

        expect(logger)
          .to have_received(:error)
          .with("Adapter failed to send count metrics for cadence.metric: #<StandardError: test>")
      end
    end
  end

  describe '#gauge' do
    it 'calls adapter' do
      subject.gauge(key, value)

      expect(adapter).to have_received(:gauge).with(key, value, {})
    end

    it 'calls adapter with tags' do
      subject.gauge(key, value, tags)

      expect(adapter).to have_received(:gauge).with(key, value, tags)
    end

    context 'when adapter fails' do
      before { allow(adapter).to receive(:gauge).and_raise(StandardError, 'test') }

      it 'logs' do
        subject.gauge(key, value)

        expect(logger)
          .to have_received(:error)
          .with("Adapter failed to send gauge metrics for cadence.metric: #<StandardError: test>")
      end
    end
  end

  describe '#timing' do
    it 'calls adapter' do
      subject.timing(key, value)

      expect(adapter).to have_received(:timing).with(key, value, {})
    end

    it 'calls adapter with tags' do
      subject.timing(key, value, tags)

      expect(adapter).to have_received(:timing).with(key, value, tags)
    end

    context 'when adapter fails' do
      before { allow(adapter).to receive(:timing).and_raise(StandardError, 'test') }

      it 'logs' do
        subject.timing(key, value)

        expect(logger)
          .to have_received(:error)
          .with("Adapter failed to send timing metrics for cadence.metric: #<StandardError: test>")
      end
    end
  end
end
