Fabricator(:api_workflow_execution_info, from: Temporal::Api::Workflow::V1::WorkflowExecutionInfo) do
  execution { Fabricate(:api_workflow_execution) }
  type { Fabricate(:api_workflow_type) }
  start_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  close_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  status { Temporal::Api::Enums::V1::WorkflowExecutionStatus::WORKFLOW_EXECUTION_STATUS_COMPLETED }
  history_length { rand(100) }
end
