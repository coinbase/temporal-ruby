require 'securerandom'

Fabricator(
  :api_workflow_execution_started_event_attributes,
  from: Temporal::Api::History::V1::WorkflowExecutionStartedEventAttributes
) do
  transient :headers

  workflow_type { Fabricate(:api_workflow_type) }
  original_execution_run_id { SecureRandom.uuid }
  attempt 1
  header do |attrs|
    fields = (attrs[:headers] || {}).each_with_object({}) do |(field, payload), h|
      h[field] = Fabricate(:api_payload, data: payload)
    end
    Temporal::Api::Common::V1::Header.new(fields: fields)
  end
end
