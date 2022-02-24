require 'workflows/query_workflow'

describe QueryWorkflow, :integration do
  subject { described_class }

  it 'returns the correct result for the queries' do
    workflow_id, run_id = run_workflow(described_class)

    # These query calls should leverage the task.queries mechanism, as there is a locally executed sleeping activity
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id)).to eq 'started'
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id, 'upcase')).to eq 'STARTED'
    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id)).to eq nil
    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id, 'reverse', 'upcase')).to eq nil
    expect(Temporal.query_workflow(described_class, 'unknown_query', workflow_id, run_id)).to eq nil

    Temporal.signal_workflow(described_class, 'finish', workflow_id, run_id)

    wait_for_workflow_completion(workflow_id, run_id)

    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id)).to eq 'finished'
    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id)).to eq 'finish'
    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id, 'reverse')).to eq 'hsinif'
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id, 'upcase')).to eq 'FINISHED'
    expect(Temporal.query_workflow(described_class, 'unknown_query', workflow_id, run_id)).to eq nil
  end
end
