Fabricator(:api_workflow_query, from: Temporalio::Api::Query::V1::WorkflowQuery) do
  query_type { 'state' }
  query_args { Temporal.configuration.converter.to_payloads(['']) }
end
