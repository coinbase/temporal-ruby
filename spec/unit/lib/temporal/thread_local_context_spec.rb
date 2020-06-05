require 'temporal/thread_local_context'

describe Temporal::ThreadLocalContext do
  subject { described_class }
  let(:context) { instance_double('Temporal::Workflow::Context') }

  after { Thread.current[described_class::WORKFLOW_CONTEXT_KEY] = nil }

  describe '.get' do
    before { Thread.current[described_class::WORKFLOW_CONTEXT_KEY] = context }

    it 'get a previously set context' do
      expect(subject.get).to eq(context)
    end
  end

  describe '.set' do
    it 'sets a new context' do
      expect { subject.set(context) }
        .to change { Thread.current[described_class::WORKFLOW_CONTEXT_KEY] }
        .from(nil)
        .to(context)
    end
  end
end
