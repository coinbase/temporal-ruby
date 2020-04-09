require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:decision_task, from: CadenceThrift::PollForDecisionTaskResponse) do
  transient :task_token, :activity_name, :headers

  startedEventId { rand(100) }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  workflowType { Fabricate(:workflow_type) }
  workflowExecution { Fabricate(:workflow_execution) }
  scheduledTimestamp { Time.now.to_f * 10**9 }
  startedTimestamp { Time.now.to_f * 10**9 }
end
