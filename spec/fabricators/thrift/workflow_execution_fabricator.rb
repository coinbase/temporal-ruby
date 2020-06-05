require 'gen/thrift/temporal_types'
require 'securerandom'

Fabricator(:workflow_execution_thrift, from: TemporalThrift::WorkflowExecution) do
  runId { SecureRandom.uuid }
  workflowId { SecureRandom.uuid }
end
