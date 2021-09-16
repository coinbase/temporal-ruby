require 'temporal/workflow/history/event'

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
end
