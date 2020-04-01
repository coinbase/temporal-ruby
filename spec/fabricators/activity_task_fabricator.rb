require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:activity_task, from: CadenceThrift::PollForActivityTaskResponse) do
  transient :task_token, :activity_name, :headers

  activityId { SecureRandom.uuid }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  activityType { |attrs| Fabricate(:activity_type, name: attrs[:activity_name]) }
  input ''
  workflowType { Fabricate(:workflow_type) }
  workflowExecution { Fabricate(:workflow_execution) }
  scheduledTimestampOfThisAttempt { Time.now.to_f * 10**9 }
  startedTimestamp { Time.now.to_f * 10**9 }
  header { |attrs| Fabricate(:header, fields: attrs[:headers]) if attrs[:headers] }
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
