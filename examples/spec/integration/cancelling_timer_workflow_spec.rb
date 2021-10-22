require 'workflows/cancelling_timer_workflow'
require 'securerandom'

describe CancellingTimerWorkflow do
  let(:workflow_id) { SecureRandom.uuid }
  let(:activity_timeout) { 0.01 }

  around do |example|
    Temporal::Testing.local! { example.run }
  end

  it 'succeeds' do
    run_id = Temporal.start_workflow(
      described_class, activity_timeout, 10, options: { workflow_id: workflow_id }
    )

    info = Temporal.fetch_workflow_execution_info('ruby-samples', workflow_id, run_id)

    expect(info.status).to eq(Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS)
  end
end
