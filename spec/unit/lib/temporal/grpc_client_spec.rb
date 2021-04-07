describe Temporal::Client::GRPCClient do
  let(:grpc_stub) { double('grpc stub') }

  describe '#start_workflow_execution' do
    it 'provides the existing run_id when the workflow is already started' do
      client = Temporal::Client::GRPCClient.new(nil, nil, nil)
      allow(client).to receive(:client).and_return(grpc_stub)
      allow(grpc_stub).to receive(:start_workflow_execution).and_raise(
        GRPC::AlreadyExists,
        'Workflow execution already finished successfully. WorkflowId: TestWorkflow-1, RunId: baaf1d86-4459-4ecd-a288-47aeae55245d. Workflow Id reuse policy: allow duplicate workflow Id if last run failed.'
      )

      expect {
        client.start_workflow_execution(
          namespace: 'test',
          workflow_id: 'TestWorkflow-1',
          workflow_name: 'Test',
          task_queue: 'test',
          execution_timeout: 0,
          run_timeout: 0,
          task_timeout: 0
        )
      }.to raise_error(Temporal::WorkflowExecutionAlreadyStartedFailure) { |e|
        expect(e.run_id).to eql('baaf1d86-4459-4ecd-a288-47aeae55245d')
      }
    end
  end
end
