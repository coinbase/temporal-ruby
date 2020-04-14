module Cadence
  class Workflow
    module Decision
      # TODO: Move these classes into their own directories under workflow/decision/*
      ScheduleActivity = Struct.new(:activity_type, :activity_id, :input, :domain, :task_list, :retry_policy, :timeouts, :headers, keyword_init: true)
      StartChildWorkflow = Struct.new(:workflow_type, :workflow_id, :input, :domain, :task_list, :retry_policy, :timeouts, :headers, keyword_init: true)
      RequestActivityCancellation = Struct.new(:activity_id, keyword_init: true)
      RecordMarker = Struct.new(:name, :details, keyword_init: true)
      StartTimer = Struct.new(:timeout, :timer_id, keyword_init: true)
      CancelTimer = Struct.new(:timer_id, keyword_init: true)
      CompleteWorkflow = Struct.new(:result, keyword_init: true)
      FailWorkflow = Struct.new(:reason, :details, keyword_init: true)

      # only these decisions are supported right now
      SCHEDULE_ACTIVITY_TYPE = :schedule_activity
      START_CHILD_WORKFLOW_TYPE = :start_child_workflow
      RECORD_MARKER_TYPE = :record_marker
      START_TIMER_TYPE = :start_timer
      CANCEL_TIMER_TYPE = :cancel_timer
      COMPLETE_WORKFLOW_TYPE = :complete_workflow
      FAIL_WORKFLOW_TYPE = :fail_workflow

      DECISION_CLASS_MAP = {
        SCHEDULE_ACTIVITY_TYPE => ScheduleActivity,
        START_CHILD_WORKFLOW_TYPE => StartChildWorkflow,
        RECORD_MARKER_TYPE => RecordMarker,
        START_TIMER_TYPE => StartTimer,
        CANCEL_TIMER_TYPE => CancelTimer,
        COMPLETE_WORKFLOW_TYPE => CompleteWorkflow,
        FAIL_WORKFLOW_TYPE => FailWorkflow
      }.freeze

      def self.generate(type, **args)
        decision_class = DECISION_CLASS_MAP[type]
        decision_class.new(**args)
      end
    end
  end
end
