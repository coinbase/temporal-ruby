require 'cadence/metrics_adapters/log'

describe Cadence::MetricsAdapters::Log do
  subject { described_class.new(logger) }
  let(:logger) { instance_double('Logger') }
  let(:key) { 'cadence.log.metric' }
  let(:value) { 42 }
  let(:tags) { { foo: 'bar', bar: 'baz' } }

  before { allow(logger).to receive(:debug) }

  describe '#count' do
    it 'logs metric' do
      subject.count(key, value, {})

      expect(logger)
        .to have_received(:debug)
        .with('cadence.log.metric | count | 42')
    end

    it 'logs metric with tags' do
      subject.count(key, value, tags)

      expect(logger)
        .to have_received(:debug)
        .with('cadence.log.metric | count | 42 | foo:bar,bar:baz')
    end
  end

  describe '#gauge' do
    it 'logs metric' do
      subject.gauge(key, value, {})

      expect(logger)
        .to have_received(:debug)
        .with('cadence.log.metric | gauge | 42')
    end

    it 'logs metric with tags' do
      subject.gauge(key, value, tags)

      expect(logger)
        .to have_received(:debug)
        .with('cadence.log.metric | gauge | 42 | foo:bar,bar:baz')
    end
  end

  describe '#timing' do
    it 'logs metric' do
      subject.timing(key, value, {})

      expect(logger)
        .to have_received(:debug)
        .with('cadence.log.metric | timing | 42')
    end

    it 'logs metric with tags' do
      subject.timing(key, value, tags)

      expect(logger)
        .to have_received(:debug)
        .with('cadence.log.metric | timing | 42 | foo:bar,bar:baz')
    end
  end
end
