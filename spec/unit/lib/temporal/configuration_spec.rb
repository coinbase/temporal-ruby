require 'temporal/configuration'

describe Temporal::Configuration do
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

  describe '#for_connection' do
    let (:new_identity) { 'new_identity' }

    it 'default identity' do
      expect(subject.for_connection).to have_attributes(identity: "#{Thread.current.object_id}@#{`hostname`}")
    end

    it 'override identity' do
      subject.identity = new_identity
      expect(subject.for_connection).to have_attributes(identity: new_identity)
    end
  end
end