require 'temporal/workflow/history/event'
require 'temporal/api/history/v1/message_pb'

describe Temporal::Workflow::History::Event do
  subject { described_class.new(raw_event) }

  describe '#initialize' do
    let(:raw_event) { Fabricate(:api_workflow_execution_started_event) }

    it 'sets correct id' do
      expect(subject.id).to eq(raw_event.event_id)
    end

    it 'sets correct timestamp' do
      current_time = Time.now
      allow(Time).to receive(:now).and_return(current_time)

      expect(subject.timestamp).to be_within(0.0001).of(current_time)
    end

    it 'sets correct type' do
      expect(subject.type).to eq('WORKFLOW_EXECUTION_STARTED')
    end

    it 'sets correct attributes' do
      expect(subject.attributes).to eq(raw_event.workflow_execution_started_event_attributes)
    end

    context 'when the event attributes are unknown to the generated proto' do
      let(:raw_event) do
        event = Temporalio::Api::History::V1::HistoryEvent.decode(unknown_attributes_event_payload)
        event.event_time = Google::Protobuf::Timestamp.new(seconds: Time.now.to_i)
        event
      end
      # Field 5000, wire type 2 (length-delimited), length 0:
      #   tag = (5000 << 3) | 2 = 40002
      #   varint(40002) = [0xC2, 0xB8, 0x02]
      let(:unknown_attributes_event_payload) do
        [
          0x08, 99, # event_id = 99
          0x18, 99, # event_type = 99 (unknown enum value)
          0xC2, 0xB8, 0x02, 0x00, # unknown oneof attributes at field 5000, length 0
          0xE0, 0x12, 0x01 # worker_may_ignore = true (field 300)
        ].pack('C*')
      end

      it 'keeps the event constructable so worker_may_ignore can be read' do
        expect(subject.attributes).to be_nil
        expect(subject.worker_may_ignore).to eq(true)
      end
    end
  end

  describe '#originating_event_id' do
    subject { described_class.new(raw_event).originating_event_id }

    context 'when event is TIMER_FIRED' do
      let(:raw_event) { Fabricate(:api_timer_fired_event, event_id: 42) }

      it { is_expected.to eq(raw_event.timer_fired_event_attributes.started_event_id) }
    end

    context 'when event is TIMER_CANCELED' do
      let(:raw_event) { Fabricate(:api_timer_canceled_event, event_id: 42) }

      it { is_expected.to eq(raw_event.event_id) }
    end
  end


  describe '#target_attributes' do
    subject { described_class.new(raw_event).target_attributes }

    context 'when event is ActivityTaskScheduled' do
      let(:input) { ['foo', 'bar', { 'foo' => 'bar' }] }
      let(:raw_event) do
        Fabricate(:activity_task_scheduled_event_thrift, eventId: 42, input: input)
      end

      it {
        is_expected.to eq({ activity_id: 42, activity_type: 'TestActivity', input: input })
      }
    end

    context 'when event is WorkflowTaskScheduled' do
      let(:input) { ['foo', 'bar', { 'foo' => 'bar' }] }
      let(:raw_event) do
        Fabricate(:workflow_task_scheduled_event_thrift, eventId: 42)
      end

      it {
        is_expected.to eq({})
      }
    end
  end
end
