require 'securerandom'

Fabricator(
  :api_workflow_execution_started_event_attributes,
  from: Temporal::Api::History::V1::WorkflowExecutionStartedEventAttributes
) do
  transient :headers

  workflow_type { Fabricate(:api_workflow_type) }
  original_execution_run_id { SecureRandom.uuid }
  attempt 1
  task_queue { Fabricate(:api_task_queue) }
  header do |attrs|
    Temporal::Api::Common::V1::Header.new(fields: $converter.to_payload_map(attrs[:headers] || {}))
  end
end
