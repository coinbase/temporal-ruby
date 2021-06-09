Fabricator(:workflow_completed_event, from: Temporal::Api::History::V1::HistoryEvent) do
  transient :result

  event_type { :EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED }
  workflow_execution_completed_event_attributes do |attrs|
    Temporal::Api::History::V1::WorkflowExecutionCompletedEventAttributes.new(
      result: attrs[:result]
    )
  end
end
