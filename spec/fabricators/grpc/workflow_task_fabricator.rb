require 'securerandom'

Fabricator(:api_workflow_task, from: Temporal::Api::WorkflowService::V1::PollWorkflowTaskQueueResponse) do
  transient :task_token, :activity_name, :headers, :events

  started_event_id { rand(100) }
  task_token { |attrs| attrs[:task_token] || SecureRandom.uuid }
  workflow_type { Fabricate(:api_workflow_type) }
  workflow_execution { Fabricate(:api_workflow_execution) }
  scheduled_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  started_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  history { |attrs| Temporal::Api::History::V1::History.new(events: attrs[:events]) }
  query { nil }
end

Fabricator(:api_paginated_workflow_task, from: :api_workflow_task) do
  next_page_token 'page-1'
end
