require 'temporal/configuration'

describe Temporal::Configuration do
  class TestHeaderPropagator
    def inject!(_); end
  end

  describe '#initialize' do
    it 'initializes proper default workflow timeouts' do 
      timeouts = subject.timeouts

      # By default, we don't ever want to timeout workflows, because workflows "always succeed" and
      # they may be long-running
      expect(timeouts[:execution]).to be >= 86_400 * 365 * 10
      expect(timeouts[:run]).to eq(timeouts[:execution])
      expect(timeouts[:task]).to eq(10)
    end

    it 'initializes proper default activity timeouts' do 
      timeouts = subject.timeouts

      # Schedule to start timeouts are dangerous because there is no retry.
      # https://docs.temporal.io/blog/activity-timeouts/#schedule-to-start-timeout recommends to use them rarely
      expect(timeouts[:schedule_to_start]).to be(nil)
      # We keep retrying until the workflow times out, by default
      expect(timeouts[:schedule_to_close]).to be(nil)
      # Activity invocations should be short-lived by default so they can be retried relatively quickly
      expect(timeouts[:start_to_close]).to eq(30)
      # No heartbeating for a default (short-lived) activity
      expect(timeouts[:heartbeat]).to be(nil)
    end
  end

  describe '#add_header_propagator' do
    let(:header_propagators) { subject.send(:header_propagators) }

    it 'adds middleware entry to the list of middlewares' do
      subject.add_header_propagator(TestHeaderPropagator)
      subject.add_header_propagator(TestHeaderPropagator, 'arg1', 'arg2')

      expect(header_propagators.size).to eq(2)

      expect(header_propagators[0]).to be_an_instance_of(Temporal::Middleware::Entry)
      expect(header_propagators[0].klass).to eq(TestHeaderPropagator)
      expect(header_propagators[0].args).to eq([])

      expect(header_propagators[1]).to be_an_instance_of(Temporal::Middleware::Entry)
      expect(header_propagators[1].klass).to eq(TestHeaderPropagator)
      expect(header_propagators[1].args).to eq(['arg1', 'arg2'])
    end
  end

  describe '#for_connection' do
    let(:new_identity) { 'new_identity' }
    let(:client_config) { { channel_args: { 'foo' => 'again' } } }
    let(:expected_client_config) { Temporal::Configuration::GRPCConfig.new(client_config) }

    it 'default identity and client_config' do
      expect(subject.for_connection).to have_attributes(identity: "#{Process.pid}@#{`hostname`}")
    end

    it 'override identity' do
      subject.identity = new_identity
      expect(subject.for_connection).to have_attributes(identity: new_identity)
    end

    it 'override client_config' do
      subject.client_config = client_config
      expect(subject.for_connection).to have_attributes(client_config: expected_client_config)
    end
  end
end
