Fabricator(:workflow_execution_history, from: Temporal::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse) do
  transient :events
  history { |attrs| Temporal::Api::History::V1::History.new(events: attrs[:events]) }
end
