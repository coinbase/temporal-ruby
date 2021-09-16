require 'temporal/workflow/history/event_target'
require 'temporal/workflow/history/event'

describe Temporal::Workflow::History::EventTarget do
  describe '.from_event' do
    subject { described_class.from_event(event) }
    let(:event) { Temporal::Workflow::History::Event.new(raw_event) }

    context 'when event is TIMER_STARTED' do
      let(:raw_event) { Fabricate(:api_timer_started_event) }

      it 'sets type to timer' do
        expect(subject.type).to eq(described_class::TIMER_TYPE)
      end
    end

    context 'when event is TIMER_CANCELED' do
      let(:raw_event) { Fabricate(:api_timer_canceled_event) }

      it 'sets type to cancel_timer_request' do
        expect(subject.type).to eq(described_class::CANCEL_TIMER_REQUEST_TYPE)
      end
    end
  end
end
