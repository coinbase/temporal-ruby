require 'workflows/query_workflow'

describe QueryWorkflow, :integration do
  subject { described_class }

  it 'returns the correct result for the queries' do
    workflow_id, run_id = run_workflow(described_class)

    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id)).to eq "waiting for cancel"
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id, 'upcase')).to eq "WAITING FOR CANCEL"

    Temporal.signal_workflow(described_class, 'cancel', workflow_id, run_id)
    wait_for_workflow_completion(workflow_id, run_id)

    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id)).to eq "cancelled"
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id, 'upcase')).to eq "CANCELLED"
  end
end
