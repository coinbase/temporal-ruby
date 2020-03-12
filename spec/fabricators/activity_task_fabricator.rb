require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:activity_task, from: CadenceThrift::PollForActivityTaskResponse) do
  transient :task_token, :activity_name

  activityId { SecureRandom.uuid }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  activityType { |attrs| Fabricate(:activity_type, name: attrs[:activity_name]) }
  input ''
  workflowType { Fabricate(:workflow_type) }
  workflowExecution { Fabricate(:workflow_execution) }
end

Fabricator(:activity_type, from: CadenceThrift::ActivityType) do
  name 'TestActivity'
end

Fabricator(:workflow_type, from: CadenceThrift::WorkflowType) do
  name 'TestWorkflow'
end

Fabricator(:workflow_execution, from: CadenceThrift::WorkflowExecution) do
  runId { SecureRandom.uuid }
  workflowId { SecureRandom.uuid }
end
