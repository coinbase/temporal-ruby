require 'gen/thrift/cadence_types'
require 'securerandom'
require 'cadence/utils'

Fabricator(:decision_task_thrift, from: CadenceThrift::PollForDecisionTaskResponse) do
  transient :task_token, :activity_name, :headers

  startedEventId { rand(100) }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  workflowType { Fabricate(:workflow_type_thrift) }
  workflowExecution { Fabricate(:workflow_execution_thrift) }
  scheduledTimestamp { Cadence::Utils.time_to_nanos(Time.now) }
  startedTimestamp { Cadence::Utils.time_to_nanos(Time.now) }
end
