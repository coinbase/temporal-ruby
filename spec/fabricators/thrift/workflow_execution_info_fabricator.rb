require 'gen/thrift/temporal_types'
require 'temporal/utils'

Fabricator(:workflow_execution_info_thrift, from: TemporalThrift::WorkflowExecutionInfo) do
  execution { Fabricate(:workflow_execution_thrift) }
  type { Fabricate(:workflow_type_thrift) }
  startTime { Temporal::Utils.time_to_nanos(Time.now) }
  closeTime { Temporal::Utils.time_to_nanos(Time.now) }
  closeStatus { TemporalThrift::WorkflowExecutionCloseStatus::COMPLETED }
  historyLength { rand(100) }
end
