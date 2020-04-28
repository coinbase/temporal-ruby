require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:workflow_execution_thrift, from: CadenceThrift::WorkflowExecution) do
  runId { SecureRandom.uuid }
  workflowId { SecureRandom.uuid }
end
