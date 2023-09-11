require 'securerandom'
require 'workflows/signal_workflow'

describe 'signal' do
  it 'all signals process' do
    workflow_id = SecureRandom.uuid
    expected_score = 7
    run_id = Temporal.start_workflow(
      SignalWorkflow,
      1, # seconds
      options: {
        workflow_id: workflow_id,
        signal_name: 'score',
        signal_input: expected_score,
        timeouts: { execution: 10 }
      }
    )

    loop do
      value = SecureRandom.rand(10)

      begin
        Temporal.signal_workflow(SignalWorkflow, 'score', workflow_id, run_id, value)
      rescue StandardError
        # Keep going until there's an error such as the workflow finishing
        break
      end
      expected_score += value
      sleep 0.01
    end

    result = Temporal.await_workflow_result(
      SignalWorkflow,
      workflow_id: workflow_id,
      run_id: run_id
    )

    expect(result).to eq(expected_score)
  end
end
