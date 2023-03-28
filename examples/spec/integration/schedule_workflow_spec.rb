require 'workflows/hello_world_workflow'

describe HelloWorldWorkflow do
  subject { described_class }

  before { allow(HelloWorldActivity).to receive(:execute!).and_call_original }

  it 'can retrieve the workflow schedule via run id' do
    workflow_id = 'schedule_test_wf'
    cron_schedule = '*/5 * * * *'

    begin
      Temporal.terminate_workflow(workflow_id)
    rescue GRPC::NotFound => _
      # The test workflow hasn't been scheduled before
    end
    
    run_id = Temporal.schedule_workflow(HelloWorldWorkflow, cron_schedule, options: {workflow_id: workflow_id})

    expect(Temporal.get_cron_schedule('ruby-samples', workflow_id, run_id: run_id)).to eq(cron_schedule)
  end

  it 'can retrieve the workflow schedule of the latest run' do
    workflow_id = 'schedule_test_wf'
    cron_schedule = '*/6 * * * *'

    begin
      Temporal.terminate_workflow(workflow_id)
    rescue GRPC::NotFound => _
      # The test workflow hasn't been scheduled before
    end
    
    Temporal.schedule_workflow(HelloWorldWorkflow, cron_schedule, options: {workflow_id: workflow_id})

    expect(Temporal.get_cron_schedule('ruby-samples', workflow_id)).to eq(cron_schedule)
  end

  it 'retrieves an empty schedule if no schedule' do
    workflow_id = 'schedule_test_wf'

    begin
      Temporal.terminate_workflow(workflow_id)
    rescue GRPC::NotFound => _
      # The test workflow hasn't been scheduled before
    end
    
    Temporal.start_workflow(HelloWorldWorkflow, options: {workflow_id: workflow_id})

    expect(Temporal.get_cron_schedule('ruby-samples', workflow_id)).to eq(nil)
  end
end
