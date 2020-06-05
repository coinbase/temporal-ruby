require 'gen/thrift/temporal_types'
require 'securerandom'
require 'temporal/utils'

Fabricator(:activity_task_thrift, from: TemporalThrift::PollForActivityTaskResponse) do
  transient :task_token, :activity_name, :headers

  activityId { SecureRandom.uuid }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  activityType { |attrs| Fabricate(:activity_type_thrift, name: attrs[:activity_name]) }
  input ''
  workflowType { Fabricate(:workflow_type_thrift) }
  workflowExecution { Fabricate(:workflow_execution_thrift) }
  scheduledTimestampOfThisAttempt { Temporal::Utils.time_to_nanos(Time.now) }
  startedTimestamp { Temporal::Utils.time_to_nanos(Time.now) }
  header { |attrs| Fabricate(:header_thrift, fields: attrs[:headers]) if attrs[:headers] }
end
