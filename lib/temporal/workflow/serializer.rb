require 'temporal/workflow/workflow_task'
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
        Workflow::WorkflowTask::ScheduleActivity => Serializer::ScheduleActivity,
        Workflow::WorkflowTask::StartChildWorkflow => Serializer::StartChildWorkflow,
        Workflow::WorkflowTask::RequestActivityCancellation => Serializer::RequestActivityCancellation,
        Workflow::WorkflowTask::RecordMarker => Serializer::RecordMarker,
        Workflow::WorkflowTask::StartTimer => Serializer::StartTimer,
        Workflow::WorkflowTask::CancelTimer => Serializer::CancelTimer,
        Workflow::WorkflowTask::CompleteWorkflow => Serializer::CompleteWorkflow,
        Workflow::WorkflowTask::FailWorkflow => Serializer::FailWorkflow
      }.freeze

      def self.serialize(object)
        serializer = SERIALIZERS_MAP[object.class]
        serializer.new(object).to_proto
      end
    end
  end
end
