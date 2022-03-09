Fabricator(:api_workflow_execution_info, from: Temporal::Api::Workflow::V1::WorkflowExecutionInfo) do
  transient :workflow_id, :workflow

  execution { |attrs| Fabricate(:api_workflow_execution, workflow_id: attrs[:workflow_id]) }
  type { |attrs| Fabricate(:api_workflow_type, name: attrs[:workflow]) }
  start_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  close_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  status { Temporal::Api::Enums::V1::WorkflowExecutionStatus::WORKFLOW_EXECUTION_STATUS_COMPLETED }
  history_length { rand(100) }
  memo { Fabricate(:memo) }
  search_attributes { Fabricate(:search_attributes) }
end
