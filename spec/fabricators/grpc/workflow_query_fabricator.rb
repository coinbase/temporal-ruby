Fabricator(:api_workflow_query, from: Temporalio::Api::Query::V1::WorkflowQuery) do
  query_type { 'state' }
  query_args { TEST_CONVERTER.to_payloads(['']) }
end
