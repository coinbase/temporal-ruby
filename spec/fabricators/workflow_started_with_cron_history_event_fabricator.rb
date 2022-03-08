Fabricator(:workflow_started_with_cron_history_event, from: Temporal::Api::History::V1::HistoryEvent) do
  transient :cron_schedule

  event_time { Google::Protobuf::Timestamp.new.tap { |t| t.from_time(Time.now) } }
  event_type { :EVENT_TYPE_WORKFLOW_EXECUTION_STARTED }
  workflow_execution_started_event_attributes do |attrs|
    Temporal::Api::History::V1::WorkflowExecutionStartedEventAttributes.new(
      cron_schedule: attrs[:cron_schedule]
    )
  end
end
