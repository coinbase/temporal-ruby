require 'temporal/workflow/decision'
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
        serializer.new(object).to_thrift
      end
    end
  end
end
