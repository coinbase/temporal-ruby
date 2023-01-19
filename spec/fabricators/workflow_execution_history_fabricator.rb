Fabricator(:workflow_execution_history, from: Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse) do
  transient :events, :_next_page_token
  history { |attrs| Temporalio::Api::History::V1::History.new(events: attrs[:events]) }
  next_page_token { |attrs| attrs[:_next_page_token] || '' }
end
