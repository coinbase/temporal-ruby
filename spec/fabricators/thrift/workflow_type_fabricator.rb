require 'gen/thrift/cadence_types'

Fabricator(:workflow_type_thrift, from: CadenceThrift::WorkflowType) do
  name 'TestWorkflow'
end
