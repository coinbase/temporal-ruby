require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(:activity_task, from: CadenceThrift::PollForActivityTaskResponse) do
  transient :task_token, :activity_name

  activityId { SecureRandom.uuid }
  taskToken { |attrs| attrs[:task_token] || SecureRandom.uuid }
  activityType { |attrs| Fabricate(:activity_type, name: attrs[:activity_name]) }
  input ''
end

Fabricator(:activity_type, from: CadenceThrift::ActivityType) do
  name 'TestActivity'
end
