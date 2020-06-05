require 'gen/thrift/temporal_types'
require 'securerandom'
require 'temporal/utils'

Fabricator(:decision_task_thrift, from: TemporalThrift::PollForDecisionTaskResponse) do
  transient :task_token, :activity_name, :headers

  startedEventId { rand(100) }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  workflowType { Fabricate(:workflow_type_thrift) }
  workflowExecution { Fabricate(:workflow_execution_thrift) }
  scheduledTimestamp { Temporal::Utils.time_to_nanos(Time.now) }
  startedTimestamp { Temporal::Utils.time_to_nanos(Time.now) }
end
