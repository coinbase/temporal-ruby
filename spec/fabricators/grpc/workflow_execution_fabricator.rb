require 'securerandom'

Fabricator(:api_workflow_execution, from: Temporal::Api::Common::V1::WorkflowExecution) do
  run_id { SecureRandom.uuid }
  workflow_id { SecureRandom.uuid }
end
