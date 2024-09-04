require 'securerandom'

Fabricator(
  :api_workflow_execution_started_event_attributes,
  from: Temporalio::Api::History::V1::WorkflowExecutionStartedEventAttributes
) do
  transient :headers

  workflow_type { Fabricate(:api_workflow_type) }
  original_execution_run_id { SecureRandom.uuid }
  attempt 1
  task_queue { Fabricate(:api_task_queue) }
  header do |attrs|
    fields = (attrs[:headers] || {}).each_with_object({}) do |(field, value), h|
      h[field] = TEST_CONVERTER.to_payload(value)
    end
    Temporalio::Api::Common::V1::Header.new(fields: fields)
  end
end
