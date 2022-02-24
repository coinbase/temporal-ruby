require 'workflows/query_workflow'

describe QueryWorkflow, :integration do
  subject { described_class }

  it 'returns the correct result for the queries' do
    workflow_id, run_id = run_workflow(described_class)

    # Target query handler for "state", no args
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id))
      .to eq 'started'

    # Target query handler for "state", arbitrary args
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id,
      'upcase', 'ignored', 'reverse'))
      .to eq 'DETRATS'

    # Target catch-all query handler, no args
    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id))
      .to be nil

    # Target catch-all query handler, arbitrary args
    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id,
      'reverse', 'many', 'extra', 'arguments', 'ignored'))
      .to be nil

    # Target catch-all query handler with unrecognized signal
    # TODO this is meant to be an error handling expectation
    expect(Temporal.query_workflow(described_class, 'unknown_query', workflow_id, run_id))
      .to be nil

    Temporal.signal_workflow(described_class, 'finish', workflow_id, run_id)
    wait_for_workflow_completion(workflow_id, run_id)

    # Repeating query scenarios above, expecting updated state and signal results
    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id))
      .to eq 'finished'

    expect(Temporal.query_workflow(described_class, 'state', workflow_id, run_id,
      'upcase', 'ignored', 'reverse'))
      .to eq 'DEHSINIF'

    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id))
      .to eq 'finish'

    expect(Temporal.query_workflow(described_class, 'last_signal', workflow_id, run_id,
      'reverse', 'many', 'extra', 'arguments', 'ignored'))
      .to eq 'hsinif'

    # TODO this is meant to be an error handling expectation
    expect(Temporal.query_workflow(described_class, 'unknown_query', workflow_id, run_id))
      .to be nil
  end
end
