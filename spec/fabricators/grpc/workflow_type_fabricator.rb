Fabricator(:api_workflow_type, from: Temporalio::Api::Common::V1::WorkflowType) do
  name 'TestWorkflow'
end
