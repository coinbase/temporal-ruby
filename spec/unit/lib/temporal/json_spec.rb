require 'temporal/json'
require 'temporal/concerns/input_deserializer'

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

    it 'round-trips a raised Exception including backtrace locations' do
      begin
        raise TemporalJSONSpecFixtures::DummyError.new('boom', code: 7)
      rescue TemporalJSONSpecFixtures::DummyError => error
        loaded = described_class.deserialize(described_class.serialize(error))

        expect(loaded).to be_a(TemporalJSONSpecFixtures::DummyError)
        expect(loaded.message).to eq('boom')
        expect(loaded.code).to eq(7)
      end
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

    it 'rejects duplicate ^o keys before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(
          '{"^o":"Gem::Requirement","^o":"TemporalJSONSpecFixtures::DummyActivity::Request"}'
        )
      end.to raise_error(Temporal::JSONDisallowedClassError, /duplicate hash key/)
    end

    it 'rejects duplicate ^u keys before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"^u":["Gem::Requirement",1],"^u":[["a"],1]}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /duplicate hash key/)
    end

    it 'rejects duplicate scope when the first value is an object' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(
          '{"^o":"TemporalJSONSpecFixtures::DummyActivity::Request","scope":{"^o":"Gem::Requirement"},"scope":"safe"}'
        )
      end.to raise_error(Temporal::JSONDisallowedClassError, /duplicate hash key/)
    end

    it 'rejects duplicate scope when the first value is a scalar' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"scope":"safe","scope":{"^o":"Gem::Requirement"}}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /duplicate hash key/)
    end

    it 'allows the same key in separate objects' do
      loaded = described_class.deserialize('[{"scope":"a"},{"scope":"b"}]')

      expect(loaded).to eq([{ 'scope' => 'a' }, { 'scope' => 'b' }])
    end

    it 'accepts nesting at MAX_NESTING' do
      depth = Temporal::JSON::MAX_NESTING
      raw = '[' * depth + '1' + ']' * depth

      node = described_class.deserialize(raw)
      depth.times { node = node.first }
      expect(node).to eq(1)
    end

    it 'rejects nesting one level above MAX_NESTING' do
      depth = Temporal::JSON::MAX_NESTING + 1
      raw = '[' * depth + '1' + ']' * depth

      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(raw)
      end.to raise_error(Temporal::JSONDisallowedClassError, /maximum nesting depth/)
    end

    it 'rejects duplicate scope when the first value is an array' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"scope":[1,2],"scope":"safe"}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /duplicate hash key/)
    end

    it 'rejects excessive nesting before Oj.load' do
      depth = Temporal::JSON::MAX_NESTING + 2
      raw = '[' * depth + '1' + ']' * depth

      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(raw)
      end.to raise_error(Temporal::JSONDisallowedClassError, /maximum nesting depth/)
    end

    it 'does not autoload constants while validating directives' do
      path = File.join(Dir.tmpdir, "temporal_json_autoload_#{Process.pid}.rb")
      File.write(path, "$TEMPORAL_JSON_AUTOLOADED = true\nmodule TemporalJSONAutoloadProbe; class Widget; end; end\n")
      $LOAD_PATH.unshift(File.dirname(path))
      Object.autoload(:TemporalJSONAutoloadProbe, path.sub(/\.rb$/, ''))

      expect do
        described_class.deserialize('{"^o":"TemporalJSONAutoloadProbe::Widget"}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /Widget/)

      expect(defined?($TEMPORAL_JSON_AUTOLOADED)).to be_nil
    ensure
      $LOAD_PATH.delete(File.dirname(path))
      File.delete(path) if File.exist?(path)
    end

    it 'rejects nested duplicate ^o keys before Oj.load' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize(
          '{"^o":"TemporalJSONSpecFixtures::DummyActivity::Request","scope":{"^o":"Gem::Requirement","^o":"TemporalJSONSpecFixtures::DummyActivity::Request","requirements":[[">=","0"]]}}'
        )
      end.to raise_error(Temporal::JSONDisallowedClassError, /duplicate hash key/)
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

    it 'round-trips Temporal::Metadata::Workflow' do
      require 'temporal/metadata/workflow'

      metadata = Temporal::Metadata::Workflow.new(
        namespace: 'ns',
        id: 'wid',
        name: 'WorkflowName',
        run_id: 'rid',
        parent_id: nil,
        parent_run_id: nil,
        attempt: 1,
        task_queue: 'default',
        headers: {},
        run_started_at: Time.at(1_700_000_000),
        memo: {}
      )
      loaded = described_class.deserialize(described_class.serialize(metadata))

      expect(loaded).to be_a(Temporal::Metadata::Workflow)
      expect(loaded.id).to eq('wid')
      expect(loaded.task_queue).to eq('default')
    end

    it 'round-trips an anonymous Struct' do
      response = Struct.new(:workflow_id, :run_id).new('wid', 'rid')
      loaded = described_class.deserialize(described_class.serialize(response))

      expect(loaded.workflow_id).to eq('wid')
      expect(loaded.run_id).to eq('rid')
    end

    it 'rejects a named Struct class that is not registered' do
      expect(Oj).not_to receive(:load)
      expect do
        described_class.deserialize('{"^u":["Range",1,7,false]}')
      end.to raise_error(Temporal::JSONDisallowedClassError, /Range/)
    end

    it 'round-trips Date via ^O odd marshaller' do
      require 'date'

      date = Date.new(2026, 9, 2)
      loaded = described_class.deserialize(described_class.serialize(date))

      expect(loaded).to eq(date)
    end
  end
end

describe Temporal::Concerns::InputDeserializer do
  let(:deserializer) do
    Class.new do
      include Temporal::Concerns::InputDeserializer
    end.new
  end

  it 'preserves newline-split go-client input' do
    input = "1012474654\n\"second input\""
    expect(deserializer.deserialize(input)).to eq([1_012_474_654, 'second input'])
  end

  it 'does not route JSONDisallowedClassError through the newline fallback' do
    expect do
      deserializer.deserialize('{"^o":"Gem::Requirement"}')
    end.to raise_error(Temporal::JSONDisallowedClassError, /Gem::Requirement/)
  end
end
