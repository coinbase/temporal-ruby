require 'temporal/json'

module TemporalJSONSpecFixtures
  module DummyActivity
    class Request
      attr_accessor :scope

      def initialize(scope: nil)
        @scope = scope
      end
    end

    class Response
      attr_accessor :count

      def initialize(count: nil)
        @count = count
      end
    end
  end

  class DummyWidget
    attr_accessor :name

    def initialize(name: nil)
      @name = name
    end
  end

  class DummyError < StandardError
    attr_reader :code

    def initialize(message = nil, code: nil)
      super(message)
      @code = code
    end
  end
end

describe Temporal::JSON do
  let(:hash) { { 'one' => 'one', two: :two, ':three' => ':three' } }
  let(:json) { '{"one":"one",":two":":two","\u003athree":"\u003athree"}' }

  around do |example|
    snapshot = described_class.allowed_class_names
    example.run
  ensure
    described_class.send(:with_allowed_classes) { |set| set.replace(snapshot) }
  end

  describe '.serialize' do
    it 'generates JSON string' do
      expect(described_class.serialize(hash)).to eq(json)
    end
  end

  describe '.deserialize' do
    it 'parses JSON string' do
      expect(described_class.deserialize(json)).to eq(hash)
    end

    it 'parses empty string to nil' do
      expect(described_class.deserialize('')).to eq(nil)
    end

    it 'parses nil' do
      expect(described_class.deserialize(nil)).to eq(nil)
    end

    it 'round-trips Time via ^t' do
      time = Time.at(1_700_000_000)
      loaded = described_class.deserialize(described_class.serialize(time))

      expect(loaded).to be_a(Time)
      expect(loaded.to_i).to eq(time.to_i)
    end

    it 'reconstitutes a loaded ::Request from Go-style ^o JSON' do
      payload = '{"^o":"TemporalJSONSpecFixtures::DummyActivity::Request","scope":"to_sync"}'
      loaded = described_class.deserialize(payload)

      expect(loaded).to be_a(TemporalJSONSpecFixtures::DummyActivity::Request)
      expect(loaded.scope).to eq('to_sync')
    end

    it 'round-trips a loaded ::Request through serialize' do
      request = TemporalJSONSpecFixtures::DummyActivity::Request.new(scope: 'to_sync')
      loaded = described_class.deserialize(described_class.serialize(request))

      expect(loaded).to be_a(TemporalJSONSpecFixtures::DummyActivity::Request)
      expect(loaded.scope).to eq('to_sync')
    end

    it 'round-trips a loaded ::Response through serialize' do
      response = TemporalJSONSpecFixtures::DummyActivity::Response.new(count: 3)
      loaded = described_class.deserialize(described_class.serialize(response))

      expect(loaded).to be_a(TemporalJSONSpecFixtures::DummyActivity::Response)
      expect(loaded.count).to eq(3)
    end

    it 'reconstitutes nested Request objects' do
      payload = '{"inner":{"^o":"TemporalJSONSpecFixtures::DummyActivity::Request","scope":"nested"}}'
      loaded = described_class.deserialize(payload)

      expect(loaded['inner']).to be_a(TemporalJSONSpecFixtures::DummyActivity::Request)
      expect(loaded['inner'].scope).to eq('nested')
    end

    it 'round-trips a loaded Exception subclass' do
      error = TemporalJSONSpecFixtures::DummyError.new('boom', code: 7)
      loaded = described_class.deserialize(described_class.serialize(error))

      expect(loaded).to be_a(TemporalJSONSpecFixtures::DummyError)
      expect(loaded.message).to eq('boom')
      expect(loaded.code).to eq(7)
    end

    it 'reconstitutes a loaded class reference via ^c' do
      expect(described_class.deserialize('{"^c":"String"}')).to eq(String)
    end

    it 'rejects ^c for an unloaded constant before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"^c":"DefinitelyNotAClassXYZ"}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /DefinitelyNotAClassXYZ/)
    end

    it 'rejects Gem::Requirement gadget payloads before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"^o":"Gem::Requirement"}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /Gem::Requirement/)
    end

    it 'rejects Kernel gadget payloads before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"^o":"Kernel"}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /Kernel/)
    end

    it 'rejects nested gadget payloads before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(
          '{"^o":"TemporalJSONSpecFixtures::DummyActivity::Request","scope":{"^o":"Gem::Requirement"}}'
        )
      end.to raise_error(Temporal::JSONDisallowedClassError, /Gem::Requirement/)
    end

    it 'rejects a ::Request name that is not a loaded constant' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"^o":"MissingActivity::Request"}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /MissingActivity::Request/)
    end

    it 'rejects an unregistered non-Request class' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(
          '{"^o":"TemporalJSONSpecFixtures::DummyWidget","name":"x"}'
        )
      end.to raise_error(Temporal::JSONDisallowedClassError, /DummyWidget/)
    end

    it 'reconstitutes a class registered with allow_class' do
      described_class.allow_class('TemporalJSONSpecFixtures::DummyWidget')
      widget = TemporalJSONSpecFixtures::DummyWidget.new(name: 'ok')
      loaded = described_class.deserialize(described_class.serialize(widget))

      expect(loaded).to be_a(TemporalJSONSpecFixtures::DummyWidget)
      expect(loaded.name).to eq('ok')
    end
  end
end
