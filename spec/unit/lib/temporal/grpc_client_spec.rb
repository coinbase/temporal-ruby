describe Temporal::Client::GRPCClient do
  subject { Temporal::Client::GRPCClient.new(nil, nil, nil) }
  let(:grpc_stub) { double('grpc stub') }
  let(:namespace) { 'test-namespace' }
  let(:workflow_id) { SecureRandom.uuid }
  let(:run_id) { SecureRandom.uuid }

  before do
    allow(subject).to receive(:client).and_return(grpc_stub)
  end

  describe '#start_workflow_execution' do
    it 'provides the existing run_id when the workflow is already started' do
      allow(grpc_stub).to receive(:start_workflow_execution).and_raise(
        GRPC::AlreadyExists,
        'Workflow execution already finished successfully. WorkflowId: TestWorkflow-1, RunId: baaf1d86-4459-4ecd-a288-47aeae55245d. Workflow Id reuse policy: allow duplicate workflow Id if last run failed.'
      )

      expect do
        subject.start_workflow_execution(
          namespace: namespace,
          workflow_id: workflow_id,
          workflow_name: 'Test',
          task_queue: 'test',
          execution_timeout: 0,
          run_timeout: 0,
          task_timeout: 0
        )
      end.to raise_error(Temporal::WorkflowExecutionAlreadyStartedFailure) do |e|
        expect(e.run_id).to eql('baaf1d86-4459-4ecd-a288-47aeae55245d')
      end
    end
  end

  describe '#get_workflow_execution_history' do
    let(:response) do
      Temporal::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse.new(
        history: Temporal::Api::History::V1::History.new,
        next_page_token: nil
      )
    end

    before { allow(grpc_stub).to receive(:get_workflow_execution_history).and_return(response) }

    it 'calls GRPC service with supplied arguments' do
      subject.get_workflow_execution_history(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      expect(grpc_stub).to have_received(:get_workflow_execution_history) do |request|
        expect(request).to be_an_instance_of(Temporal::Api::WorkflowService::V1::GetWorkflowExecutionHistoryRequest)
        expect(request.namespace).to eq(namespace)
        expect(request.execution.workflow_id).to eq(workflow_id)
        expect(request.execution.run_id).to eq(run_id)
        expect(request.next_page_token).to be_empty
        expect(request.wait_new_event).to eq(false)
        expect(request.history_event_filter_type).to eq(
          Temporal::Api::Enums::V1::HistoryEventFilterType.lookup(
            Temporal::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_ALL_EVENT
          )
        )
      end
    end

    context 'when wait_for_new_event is true' do
      it 'calls GRPC service' do
        subject.get_workflow_execution_history(
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          wait_for_new_event: true
        )

        expect(grpc_stub).to have_received(:get_workflow_execution_history) do |request|
          expect(request.wait_new_event).to eq(true)
        end
      end
    end

    context 'when event_type is :close' do
      it 'calls GRPC service' do
        subject.get_workflow_execution_history(
          namespace: namespace,
          workflow_id: workflow_id,
          run_id: run_id,
          event_type: :close
        )

        expect(grpc_stub).to have_received(:get_workflow_execution_history) do |request|
          expect(request.history_event_filter_type).to eq(
            Temporal::Api::Enums::V1::HistoryEventFilterType.lookup(
              Temporal::Api::Enums::V1::HistoryEventFilterType::HISTORY_EVENT_FILTER_TYPE_CLOSE_EVENT
            )
          )
        end
      end
    end
  end
end
