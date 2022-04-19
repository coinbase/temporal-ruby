Fabricator(:api_workflow_query, from: Temporal::Api::Query::V1::WorkflowQuery) do
  query_type { 'state' }
  query_args { Temporal.configuration.converter.to_payloads(['']) }
end
