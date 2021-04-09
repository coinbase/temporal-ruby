require 'temporal/workflow/command'
require 'temporal/client/serializer/schedule_activity'
require 'temporal/client/serializer/start_child_workflow'
require 'temporal/client/serializer/request_activity_cancellation'
require 'temporal/client/serializer/record_marker'
require 'temporal/client/serializer/start_timer'
require 'temporal/client/serializer/cancel_timer'
require 'temporal/client/serializer/complete_workflow'
require 'temporal/client/serializer/continue_as_new'
require 'temporal/client/serializer/fail_workflow'

module Temporal
  module Client
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
        Workflow::Command::FailWorkflow => Serializer::FailWorkflow
      }.freeze

      def self.serialize(object)
        serializer = SERIALIZERS_MAP[object.class]
        serializer.new(object).to_proto
      end
    end
  end
end
