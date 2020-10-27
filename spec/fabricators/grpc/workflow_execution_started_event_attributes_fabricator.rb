require 'securerandom'

Fabricator(
  :api_workflow_execution_started_event_attributes,
  from: Temporal::Api::History::V1::WorkflowExecutionStartedEventAttributes
) do
  transient :headers

  workflow_type { Fabricate(:api_workflow_type) }
  original_execution_run_id { SecureRandom.uuid }
  attempt 1
  header { |attrs| Fabricate(:api_header, fields: attrs[:headers]) if attrs[:headers] }
end
