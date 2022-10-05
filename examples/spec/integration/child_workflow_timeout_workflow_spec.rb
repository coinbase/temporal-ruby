require 'workflows/child_workflow_timeout_workflow.rb'

describe ChildWorkflowTimeoutWorkflow do
  subject { described_class }

  it 'successfully can catch if a child workflow times out' do
    workflow_id = SecureRandom.uuid

    Temporal.start_workflow(
      subject,
      options: { workflow_id: workflow_id }
    )

    result = Temporal.await_workflow_result(
      subject,
      workflow_id: workflow_id
    )

    expect(result).to eq({
                          child_workflow_failed: true, # true dictates the workflow detected the child workflow failure!
                        })
  end
end
