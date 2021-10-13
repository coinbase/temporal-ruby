require 'workflows/hello_world_workflow'

describe HelloWorldWorkflow do
  subject { described_class }

  before { allow(HelloWorldActivity).to receive(:execute!).and_call_original }

  it 'gets memo from workflow execution info' do
    workflow_id = 'memo_test_wf'

    begin
      Temporal.terminate_workflow(workflow_id)
    rescue GRPC::NotFound => _
      # The test workflow hasn't been scheduled before
    end
    
    Temporal.start_workflow(HelloWorldWorkflow, options: {workflow_id: workflow_id, memo: { 'foo' => 'bar' } })

    expect(Temporal.fetch_workflow_execution_info('ruby-samples', workflow_id, nil).memo).to eq({ 'foo' => 'bar' })
  end
end
