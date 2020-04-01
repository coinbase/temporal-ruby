require 'gen/thrift/cadence_types'
require 'securerandom'

Fabricator(
  :worklfow_execution_started_event_attributes,
  from: CadenceThrift::WorkflowExecutionStartedEventAttributes
) do
  transient :headers

  originalExecutionRunId { SecureRandom.uuid }
  attempt 1
  header { |attrs| Fabricate(:header, fields: attrs[:headers]) if attrs[:headers] }
end
