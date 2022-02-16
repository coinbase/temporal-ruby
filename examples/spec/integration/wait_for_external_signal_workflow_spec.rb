require 'workflows/wait_for_external_signal_workflow'
require 'workflows/send_signal_to_external_workflow'

describe WaitForExternalSignalWorkflow do
  let(:signal_name) { "signal_name" }
  let(:receiver_workflow_id) { SecureRandom.uuid }
  let(:sender_workflow_id) { SecureRandom.uuid }

  context 'when the workflows succeed then' do
    it 'receives signal from an external workflow only once' do
      run_id = Temporal.start_workflow(
        WaitForExternalSignalWorkflow,
        signal_name,
        options: {workflow_id: receiver_workflow_id}
      )

      Temporal.start_workflow(
        SendSignalToExternalWorkflow,
        signal_name,
        receiver_workflow_id
      )

      result = Temporal.await_workflow_result(
        WaitForExternalSignalWorkflow,
        workflow_id: receiver_workflow_id,
        run_id: run_id,
      )

      expect(result).to eq(
        {
          received: {
            signal_name => ["arg1", "arg2"]
          },
          counts: {
            signal_name => 1
          }
        }
      )
    end

    it 'returns :success to the sending workflow' do
      Temporal.start_workflow(
        WaitForExternalSignalWorkflow,
        signal_name,
        options: {workflow_id: receiver_workflow_id}
      )

      run_id = Temporal.start_workflow(
        SendSignalToExternalWorkflow,
        signal_name,
        receiver_workflow_id,
        options: {workflow_id: sender_workflow_id}
      )

      result = Temporal.await_workflow_result(
        SendSignalToExternalWorkflow,
        workflow_id: sender_workflow_id,
        run_id: run_id,
      )

      expect(result).to eq(:success)
    end
  end

  context 'when the workflows fail' do
    it 'correctly handles failure to deliver' do
      run_id = Temporal.start_workflow(
        SendSignalToExternalWorkflow,
        signal_name,
        receiver_workflow_id,
        options: {workflow_id: sender_workflow_id})

      result = Temporal.await_workflow_result(
        SendSignalToExternalWorkflow,
        workflow_id: sender_workflow_id,
        run_id: run_id,
      )

      expect(result).to eq(:failed)
    end
  end
end
