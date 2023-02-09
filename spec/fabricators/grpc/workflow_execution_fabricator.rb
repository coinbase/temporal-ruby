require 'securerandom'

Fabricator(:api_workflow_execution, from: Temporalio::Api::Common::V1::WorkflowExecution) do
  run_id { SecureRandom.uuid }
  workflow_id { SecureRandom.uuid }
end
