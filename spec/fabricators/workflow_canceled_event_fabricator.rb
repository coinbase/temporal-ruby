Fabricator(:workflow_canceled_event, from: Temporal::Api::History::V1::HistoryEvent) do
  event_type { :EVENT_TYPE_WORKFLOW_EXECUTION_CANCELED }
  workflow_execution_canceled_event_attributes do
    Temporal::Api::History::V1::WorkflowExecutionCanceledEventAttributes.new
  end
end
