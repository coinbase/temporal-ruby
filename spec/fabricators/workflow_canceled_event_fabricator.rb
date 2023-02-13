Fabricator(:workflow_canceled_event, from: Temporalio::Api::History::V1::HistoryEvent) do
  event_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  event_type { :EVENT_TYPE_WORKFLOW_EXECUTION_CANCELED }
  workflow_execution_canceled_event_attributes do
    Temporalio::Api::History::V1::WorkflowExecutionCanceledEventAttributes.new
  end
end
