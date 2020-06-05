require 'gen/thrift/temporal_types'

Fabricator(:workflow_type_thrift, from: TemporalThrift::WorkflowType) do
  name 'TestWorkflow'
end
