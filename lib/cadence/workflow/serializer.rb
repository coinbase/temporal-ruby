require 'cadence/workflow/decision'
require 'cadence/workflow/serializer/schedule_activity'
require 'cadence/workflow/serializer/start_child_workflow'
require 'cadence/workflow/serializer/request_activity_cancellation'
require 'cadence/workflow/serializer/record_marker'
require 'cadence/workflow/serializer/start_timer'
require 'cadence/workflow/serializer/cancel_timer'
require 'cadence/workflow/serializer/complete_workflow'
require 'cadence/workflow/serializer/fail_workflow'

module Cadence
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
