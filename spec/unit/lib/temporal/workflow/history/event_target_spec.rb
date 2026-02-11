require 'temporal/workflow/history/event_target'
require 'temporal/workflow/history/event'
require 'temporal/workflow/command'

describe Temporal::Workflow::History::EventTarget do
  describe '.from_event' do
    subject { described_class.from_event(event) }
    let(:event) { Temporal::Workflow::History::Event.new(raw_event) }

    context 'when event is TIMER_STARTED' do
      let(:raw_event) { Fabricate(:api_timer_started_event, eventId: 42) }

      it 'sets id and type' do
        expect(subject.id).to eq(42)
        expect(subject.type).to eq(described_class::TIMER_TYPE)
        expect(subject.attributes).to eq({})
      end
    end

    context 'when event is TIMER_CANCELED' do
      let(:raw_event) { Fabricate(:api_timer_canceled_event,  eventId: 42) }

      it 'sets id and type' do
        expect(subject.id).to eq(42)
        expect(subject.type).to eq(described_class::CANCEL_TIMER_REQUEST_TYPE)
        expect(subject.attributes).to eq({})
      end
    end

    context 'when event is ScheduleActivity' do
      let(:input) { ['foo', 'bar', { 'foo' => 'bar' }] }
      let(:raw_event) { Fabricate(:activity_task_scheduled_event_thrift, eventId: 42, input: input) }

      it 'sets id, type and attributes' do
        expect(subject.id).to eq(42)
        expect(subject.type).to eq(described_class::ACTIVITY_TYPE)
        expect(subject.attributes).to eq({ activity_id: 42, activity_type: 'TestActivity', input: input })
      end
    end
  end

  describe '.from_decision' do
    subject { described_class.from_command(42, decision) }

    context 'when decision is ScheduleActivity' do
      let(:raw_decision) { { activity_type: 'foo', activity_id: 123, input: ['bar'] } }
      let(:decision) { Temporal::Workflow::Command::ScheduleActivity.new(**raw_decision) }

      it 'sets id, type' do
        expect(subject.id).to eq(42)
        expect(subject.type).to eq(described_class::ACTIVITY_TYPE)
      end

      it 'sets and slice the attributes' do
        expect(raw_decision).to include(subject.attributes)
        expect(subject.attributes.keys).to eq(%i[activity_id activity_type input])
      end
    end

    context 'when decision is StartTimer' do
      let(:raw_decision) { { timeout: 10, timer_id: 123 } }
      let(:decision) { Temporal::Workflow::Command::StartTimer.new(**raw_decision) }

      it 'sets id, type' do
        expect(subject.id).to eq(42)
        expect(subject.type).to eq(described_class::TIMER_TYPE)
      end

      it 'sets empty attributes' do
        expect(subject.attributes.keys).to eq([])
      end
    end
  end

  describe '#==' do
    subject do
      described_class.new(id, type, attributes: attributes) ==
        described_class.new(42, 'type', attributes: { foo: 'bar' })
    end
    let(:id) { 42 }
    let(:type) { 'type' }
    let(:attributes) { { foo: 'bar' } }

    context 'when all value are the same' do
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when id are different' do
      let(:id) { 1 }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when type are different' do
      let(:type) { 'other_type' }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe '#attributes_equal?' do
    # Plain Ruby class without custom == (simulates workflow/activity Request)
    let(:request_class) do
      Class.new do
        attr_reader :id, :name

        def initialize(id:, name:)
          @id = id
          @name = name
        end
      end
    end

    let(:custom_eq_class) do
      Class.new do
        attr_reader :id, :name

        def initialize(id:, name:)
          @id = id
          @name = name
        end

        def ==(other)
          other.is_a?(self.class) && id == other.id
        end
      end
    end

    context 'when attributes contain plain objects without custom ==' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          activity_id: 1,
          activity_type: 'MyActivity',
          input: [request_class.new(id: 42, name: 'test')]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          activity_id: 1,
          activity_type: 'MyActivity',
          input: [request_class.new(id: 42, name: 'test')]
        })
      end

      it 'returns true when values are identical' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be true
      end

      it 'would fail with default != comparison' do
        # Prove that Ruby default == would fail (different object identities)
        expect(target_a.attributes != target_b.attributes).to be true
      end
    end

    context 'when attributes contain objects with custom ==' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          input: [custom_eq_class.new(id: 7, name: 'alpha')]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          input: [custom_eq_class.new(id: 7, name: 'beta')]
        })
      end

      it 'uses the custom == implementation' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be true
      end
    end

    context 'when attributes contain different values' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          input: [request_class.new(id: 42, name: 'test')]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          input: [request_class.new(id: 99, name: 'other')]
        })
      end

      it 'returns false' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be false
      end
    end

    context 'when attributes contain standard types only' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          activity_id: 1,
          activity_type: 'MyActivity',
          input: ['foo', 'bar', { 'key' => 'value' }]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          activity_id: 1,
          activity_type: 'MyActivity',
          input: ['foo', 'bar', { 'key' => 'value' }]
        })
      end

      it 'returns true' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be true
      end
    end

    context 'when attributes contain hashes with symbol and string keys' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          input: [{ foo: 'bar', nested: { baz: 1 } }]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          input: [{ 'foo' => 'bar', 'nested' => { 'baz' => 1 } }]
        })
      end

      it 'treats symbol and string keys as equivalent' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be true
      end
    end

    context 'when hashes contain duplicate symbol and string keys' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          input: [{ foo: 'bar', 'foo' => 'bar' }]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          input: [{ 'foo' => 'bar' }]
        })
      end

      it 'returns false to avoid ambiguous key comparisons' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be false
      end
    end

    context 'when attributes have different keys' do
      let(:target_a) do
        described_class.new(1, :activity, attributes: { a: 1 })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: { b: 1 })
      end

      it 'returns false' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be false
      end
    end

    context 'when both attributes are empty' do
      let(:target_a) { described_class.new(1, :timer, attributes: {}) }
      let(:target_b) { described_class.new(1, :timer, attributes: {}) }

      it 'returns true' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be true
      end
    end

    context 'when one attributes is nil' do
      let(:target) { described_class.new(1, :timer, attributes: { a: 1 }) }

      it 'returns false' do
        expect(target.attributes_equal?(nil)).to be false
      end
    end

    context 'with nested plain objects' do
      let(:inner_class) do
        Class.new do
          attr_reader :value
          def initialize(value:)
            @value = value
          end
        end
      end

      let(:outer_class) do
        ic = inner_class
        Class.new do
          attr_reader :inner
          define_method(:initialize) do |inner:|
            @inner = ic.new(value: inner)
          end
        end
      end

      let(:target_a) do
        described_class.new(1, :activity, attributes: {
          input: [outer_class.new(inner: 'hello')]
        })
      end

      let(:target_b) do
        described_class.new(1, :activity, attributes: {
          input: [outer_class.new(inner: 'hello')]
        })
      end

      it 'recursively compares nested objects' do
        expect(target_a.attributes_equal?(target_b.attributes)).to be true
      end
    end
  end

  describe '.from_event for specific event types' do
    subject { described_class.from_event(event) }
    let(:event) { Temporal::Workflow::History::Event.new(raw_event) }

    context 'when event is ACTIVITY_CANCELED' do
      let(:raw_event) { Fabricate(:api_activity_task_canceled_event) }

      it 'sets type to activity' do
        expect(subject.type).to eq(described_class::ACTIVITY_TYPE)
      end
    end

    context 'when event is ACTIVITY_TASK_CANCEL_REQUESTED' do
      let(:raw_event) { Fabricate(:api_activity_task_cancel_requested_event) }

      it 'sets type to cancel_activity_request' do
        expect(subject.type).to eq(described_class::CANCEL_ACTIVITY_REQUEST_TYPE)
      end
    end
  end
end
