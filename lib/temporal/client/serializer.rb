require 'temporal/workflow/decision'
require 'temporal/client/serializer/schedule_activity'
require 'temporal/client/serializer/start_child_workflow'
require 'temporal/client/serializer/request_activity_cancellation'
require 'temporal/client/serializer/record_marker'
require 'temporal/client/serializer/start_timer'
require 'temporal/client/serializer/cancel_timer'
require 'temporal/client/serializer/complete_workflow'
require 'temporal/client/serializer/fail_workflow'

module Temporal
  module Client
    module Serializer
      SERIALIZERS_MAP = {
        Workflow::Decision::ScheduleActivity => Serializer::ScheduleActivity,
        Workflow::Decision::StartChildWorkflow => Serializer::StartChildWorkflow,
        Workflow::Decision::RequestActivityCancellation => Serializer::RequestActivityCancellation,
        Workflow::Decision::RecordMarker => Serializer::RecordMarker,
        Workflow::Decision::StartTimer => Serializer::StartTimer,
        Workflow::Decision::CancelTimer => Serializer::CancelTimer,
        Workflow::Decision::CompleteWorkflow => Serializer::CompleteWorkflow,
        Workflow::Decision::FailWorkflow => Serializer::FailWorkflow
      }.freeze

      def self.serialize(object)
        serializer = SERIALIZERS_MAP[object.class]
        serializer.new(object).to_proto
      end
    end
  end
end
