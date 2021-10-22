require 'workflows/async_activity_workflow'
require 'securerandom'

describe AsyncActivityWorkflow do
  let(:workflow_id) { SecureRandom.uuid }

  around do |example|
    Temporal::Testing.local! { example.run }
  ensure
    $async_token = nil
  end

  context 'when activity completes' do
    it 'succeeds' do
      run_id = Temporal.start_workflow(described_class, options: { workflow_id: workflow_id })
      Temporal.complete_activity($async_token)

      info = Temporal.fetch_workflow_execution_info('ruby-samples', workflow_id, run_id)

      expect(info.status).to eq(Temporal::Workflow::ExecutionInfo::COMPLETED_STATUS)
    end
  end

  context 'when activity fails' do
    it 'fails' do
      run_id = Temporal.start_workflow(described_class, options: { workflow_id: workflow_id })
      Temporal.fail_activity($async_token, StandardError.new('test failure'))

      info = Temporal.fetch_workflow_execution_info('ruby-samples', workflow_id, run_id)

      expect(info.status).to eq(Temporal::Workflow::ExecutionInfo::FAILED_STATUS)
    end
  end
end