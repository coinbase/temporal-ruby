require 'workflows/async_timer_workflow'
require 'securerandom'

describe AsyncTimerWorkflow do
  let(:workflow_id) { SecureRandom.uuid }

  around do |example|
    Temporal::Testing.local! { example.run }
  end

  it 'succeeds' do
    run_id = Temporal.start_workflow(described_class, options: { workflow_id: workflow_id })
    Temporal.fire_timer(workflow_id, run_id, 1)

    info = Temporal.fetch_workflow_execution_info('ruby-samples', workflow_id, run_id)

    expect(info.status).to eq(Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS)
  end

  it 'executes HelloWorldActivity' do
    expect_any_instance_of(HelloWorldActivity)
      .to receive(:execute)
            .with('timer')
            .and_call_original

    run_id = Temporal.start_workflow(described_class, options: { workflow_id: workflow_id })
    Temporal.fire_timer(workflow_id, run_id, 1)
  end
end