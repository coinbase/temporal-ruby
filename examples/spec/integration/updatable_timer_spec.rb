require 'workflows/updatable_timer'

describe UpdatableTimer, :integration do
  let(:initial_duration) { 5 }
  let(:final_duration) { 1.1 }

  it 'updates timer duration via signal' do
    workflow_id, run_id = run_workflow(UpdatableTimer, initial_duration)
    Temporal.signal_workflow(UpdatableTimer, 'update_timer', workflow_id, run_id, 3)
    Temporal.signal_workflow(UpdatableTimer, 'update_timer', workflow_id, run_id, final_duration)

    e2e_duration = Temporal.await_workflow_result(
      UpdatableTimer,
      workflow_id: workflow_id,
      run_id: run_id,
    )

    latency_tolerance = 0.2
    expect(e2e_duration).to be > final_duration
    expect(e2e_duration).to be < final_duration + latency_tolerance
  end
end
