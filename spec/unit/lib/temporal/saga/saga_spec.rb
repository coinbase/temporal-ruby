require 'temporal/saga/saga'

describe Temporal::Saga::Saga do
  subject { described_class.new(context) }

  let(:context) { instance_double('Temporal::Workflow::Context') }

  class TestSagaActivity < Temporal::Activity; end

  describe '#add_compensation' do
    let(:compensations) { subject.send(:compensations) }

    it 'adds activity by name' do
      subject.add_compensation('SomeActivity', 42, options: { namespace: 'test', task_list: 'test' })

      expect(compensations)
        .to eq([['SomeActivity', [42, options: { namespace: 'test', task_list: 'test' }]]])
    end

    it 'adds activity by class' do
      subject.add_compensation(TestSagaActivity, 42)

      expect(compensations).to eq([[TestSagaActivity, [42]]])
    end
  end

  describe '#compensate' do
    before { allow(context).to receive(:execute_activity!) }

    context 'when there are no compensations' do
      it 'does nothing' do
        subject.compensate

        expect(context).not_to have_received(:execute_activity!)
      end
    end

    context 'when there are added compensations' do
      before do
        subject.add_compensation(TestSagaActivity, 42)
        subject.add_compensation('SomeActivity', 42, options: { namespace: 'test', task_list: 'test' })
      end

      it 'performs compensating activities in reverse order' do
        subject.compensate

        expect(context)
          .to have_received(:execute_activity!)
          .with('SomeActivity', 42, options: { namespace: 'test', task_list: 'test' })
          .ordered

        expect(context)
          .to have_received(:execute_activity!)
          .with(TestSagaActivity, 42)
          .ordered
      end
    end
  end
end
