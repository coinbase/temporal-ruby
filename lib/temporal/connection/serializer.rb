require 'temporal/workflow/command'
require 'temporal/workflow/query_result'
require 'temporal/connection/serializer/schedule_activity'
require 'temporal/connection/serializer/start_child_workflow'
require 'temporal/connection/serializer/request_activity_cancellation'
require 'temporal/connection/serializer/record_marker'
require 'temporal/connection/serializer/start_timer'
require 'temporal/connection/serializer/cancel_timer'
require 'temporal/connection/serializer/complete_workflow'
require 'temporal/connection/serializer/continue_as_new'
require 'temporal/connection/serializer/fail_workflow'
require 'temporal/connection/serializer/signal_external_workflow'
require 'temporal/connection/serializer/upsert_search_attributes'
require 'temporal/connection/serializer/query_answer'
require 'temporal/connection/serializer/query_failure'

module Temporal
  module Connection
    module Serializer
      SERIALIZERS_MAP = {
        Workflow::Command::ScheduleActivity => Serializer::ScheduleActivity,
        Workflow::Command::StartChildWorkflow => Serializer::StartChildWorkflow,
        Workflow::Command::RequestActivityCancellation => Serializer::RequestActivityCancellation,
        Workflow::Command::RecordMarker => Serializer::RecordMarker,
        Workflow::Command::StartTimer => Serializer::StartTimer,
        Workflow::Command::CancelTimer => Serializer::CancelTimer,
        Workflow::Command::CompleteWorkflow => Serializer::CompleteWorkflow,
        Workflow::Command::ContinueAsNew => Serializer::ContinueAsNew,
        Workflow::Command::FailWorkflow => Serializer::FailWorkflow,
        Workflow::Command::SignalExternalWorkflow => Serializer::SignalExternalWorkflow,
        Workflow::Command::UpsertSearchAttributes => Serializer::UpsertSearchAttributes,
        Workflow::QueryResult::Answer => Serializer::QueryAnswer,
        Workflow::QueryResult::Failure => Serializer::QueryFailure,
      }.freeze

      def self.serialize(object)
        serializer = SERIALIZERS_MAP[object.class]
        serializer.new(object).to_proto
      end
    end
  end
end
