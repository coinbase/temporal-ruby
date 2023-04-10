Fabricator(:api_record_activity_heartbeat_response, from: Temporalio::Api::WorkflowService::V1::RecordActivityTaskHeartbeatResponse) do
  cancel_requested false
end
