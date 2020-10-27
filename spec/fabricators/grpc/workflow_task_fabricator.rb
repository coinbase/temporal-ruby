require 'securerandom'

Fabricator(:api_workflow_task, from: Temporal::Api::WorkflowService::V1::PollWorkflowTaskQueueResponse) do
  transient :task_token, :activity_name, :headers

  started_event_id { rand(100) }
  task_token { |attrs| attrs[:task_token] || SecureRandom.uuid }
  workflow_type { Fabricate(:api_workflow_type) }
  workflow_execution { Fabricate(:api_workflow_execution) }
  scheduled_timestamp { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  started_timestamp { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
end
