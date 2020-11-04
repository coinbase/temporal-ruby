require 'temporal/workflow/command'
require 'temporal/workflow/serializer/schedule_activity'
require 'temporal/workflow/serializer/start_child_workflow'
require 'temporal/workflow/serializer/request_activity_cancellation'
require 'temporal/workflow/serializer/record_marker'
require 'temporal/workflow/serializer/start_timer'
require 'temporal/workflow/serializer/cancel_timer'
require 'temporal/workflow/serializer/complete_workflow'
require 'temporal/workflow/serializer/fail_workflow'

module Temporal
  class Workflow
    module Serializer
      SERIALIZERS_MAP = {
        Workflow::Command::ScheduleActivity => Serializer::ScheduleActivity,
        Workflow::Command::StartChildWorkflow => Serializer::StartChildWorkflow,
        Workflow::Command::RequestActivityCancellation => Serializer::RequestActivityCancellation,
        Workflow::Command::RecordMarker => Serializer::RecordMarker,
        Workflow::Command::StartTimer => Serializer::StartTimer,
        Workflow::Command::CancelTimer => Serializer::CancelTimer,
        Workflow::Command::CompleteWorkflow => Serializer::CompleteWorkflow,
        Workflow::Command::FailWorkflow => Serializer::FailWorkflow
      }.freeze

      def self.serialize(object)
        serializer = SERIALIZERS_MAP[object.class]
        serializer.new(object).to_proto
      end
    end
  end
end
