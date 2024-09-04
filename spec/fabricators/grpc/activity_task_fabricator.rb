require 'securerandom'

Fabricator(:api_activity_task, from: Temporalio::Api::WorkflowService::V1::PollActivityTaskQueueResponse) do
  transient :task_token, :activity_name, :headers

  activity_id { SecureRandom.uuid }
  task_token { |attrs| attrs[:task_token] || SecureRandom.uuid }
  activity_type { Fabricate(:api_activity_type) }
  input { TEST_CONVERTER.to_payloads(nil) }
  workflow_type { Fabricate(:api_workflow_type) }
  workflow_execution { Fabricate(:api_workflow_execution) }
  current_attempt_scheduled_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  started_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  scheduled_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  current_attempt_scheduled_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  header do |attrs|
    fields = (attrs[:headers] || {}).each_with_object({}) do |(field, value), h|
      h[field] = TEST_CONVERTER.to_payload(value)
    end
    Temporalio::Api::Common::V1::Header.new(fields: fields)
  end
  heartbeat_timeout { Google::Protobuf::Duration.new }
end
