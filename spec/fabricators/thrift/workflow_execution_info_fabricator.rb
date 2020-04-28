require 'gen/thrift/cadence_types'
require 'cadence/utils'

Fabricator(:workflow_execution_info_thrift, from: CadenceThrift::WorkflowExecutionInfo) do
  execution { Fabricate(:workflow_execution_thrift) }
  type { Fabricate(:workflow_type_thrift) }
  startTime { Cadence::Utils.time_to_nanos(Time.now) }
  closeTime { Cadence::Utils.time_to_nanos(Time.now) }
  closeStatus { CadenceThrift::WorkflowExecutionCloseStatus::COMPLETED }
  historyLength { rand(100) }
end
