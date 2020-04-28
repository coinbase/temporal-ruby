require 'gen/thrift/cadence_types'
require 'securerandom'
require 'cadence/utils'

Fabricator(:activity_task_thrift, from: CadenceThrift::PollForActivityTaskResponse) do
  transient :task_token, :activity_name, :headers

  activityId { SecureRandom.uuid }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  activityType { |attrs| Fabricate(:activity_type_thrift, name: attrs[:activity_name]) }
  input ''
  workflowType { Fabricate(:workflow_type_thrift) }
  workflowExecution { Fabricate(:workflow_execution_thrift) }
  scheduledTimestampOfThisAttempt { Cadence::Utils.time_to_nanos(Time.now) }
  startedTimestamp { Cadence::Utils.time_to_nanos(Time.now) }
  header { |attrs| Fabricate(:header_thrift, fields: attrs[:headers]) if attrs[:headers] }
end
