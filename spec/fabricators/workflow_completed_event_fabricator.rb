Fabricator(:workflow_completed_event, from: Temporalio::Api::History::V1::HistoryEvent) do
  transient :result

  event_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  event_type { :EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED }
  workflow_execution_completed_event_attributes do |attrs|
    Temporalio::Api::History::V1::WorkflowExecutionCompletedEventAttributes.new(
      result: attrs[:result]
    )
  end
end
