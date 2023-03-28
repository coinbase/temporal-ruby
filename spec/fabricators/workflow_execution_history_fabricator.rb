Fabricator(:workflow_execution_history, from: Temporalio::Api::WorkflowService::V1::GetWorkflowExecutionHistoryResponse) do
  transient :events, :no_history, :_next_page_token
  history { |attrs| attrs[:no_history] ? nil : Temporalio::Api::History::V1::History.new(events: attrs[:events]) }
  next_page_token { |attrs| attrs[:_next_page_token] || '' }
end
