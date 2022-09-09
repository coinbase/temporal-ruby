module Temporal
  class Workflow
    module Command
      # TODO: Move these classes into their own directories under workflow/command/*
      ScheduleActivity = Struct.new(:activity_type, :activity_id, :input, :namespace, :task_queue, :retry_policy, :timeouts, :headers, keyword_init: true)
      StartChildWorkflow = Struct.new(:workflow_type, :workflow_id, :input, :namespace, :task_queue, :retry_policy, :parent_close_policy, :timeouts, :headers, :cron_schedule, :memo, :workflow_id_reuse_policy, :search_attributes, keyword_init: true)
      ContinueAsNew = Struct.new(:workflow_type, :task_queue, :input, :timeouts, :retry_policy, :headers, :memo, :search_attributes, keyword_init: true)
      RequestActivityCancellation = Struct.new(:activity_id, keyword_init: true)
      RecordMarker = Struct.new(:name, :details, keyword_init: true)
      StartTimer = Struct.new(:timeout, :timer_id, keyword_init: true)
      CancelTimer = Struct.new(:timer_id, keyword_init: true)
      CompleteWorkflow = Struct.new(:result, keyword_init: true)
      FailWorkflow = Struct.new(:exception, keyword_init: true)
      SignalExternalWorkflow = Struct.new(:namespace, :execution, :signal_name, :input, :child_workflow_only, keyword_init: true)
      UpsertSearchAttributes = Struct.new(:search_attributes, keyword_init: true)

      # only these commands are supported right now
      SCHEDULE_ACTIVITY_TYPE = :schedule_activity
      START_CHILD_WORKFLOW_TYPE = :start_child_workflow
      CONTINUE_AS_NEW = :continue_as_new
      RECORD_MARKER_TYPE = :record_marker
      START_TIMER_TYPE = :start_timer
      CANCEL_TIMER_TYPE = :cancel_timer
      COMPLETE_WORKFLOW_TYPE = :complete_workflow
      FAIL_WORKFLOW_TYPE = :fail_workflow
      SIGNAL_EXTERNAL_WORKFLOW_TYPE = :signal_external_workflow
      UPSERT_SEARCH_ATTRIBUTES_TYPE = :upsert_search_attributes

      COMMAND_CLASS_MAP = {
        SCHEDULE_ACTIVITY_TYPE => ScheduleActivity,
        START_CHILD_WORKFLOW_TYPE => StartChildWorkflow,
        CONTINUE_AS_NEW => ContinueAsNew,
        RECORD_MARKER_TYPE => RecordMarker,
        START_TIMER_TYPE => StartTimer,
        CANCEL_TIMER_TYPE => CancelTimer,
        COMPLETE_WORKFLOW_TYPE => CompleteWorkflow,
        FAIL_WORKFLOW_TYPE => FailWorkflow,
        SIGNAL_EXTERNAL_WORKFLOW_TYPE => SignalExternalWorkflow,
        UPSERT_SEARCH_ATTRIBUTES_TYPE => UpsertSearchAttributes,
      }.freeze

      def self.generate(type, **args)
        command_class = COMMAND_CLASS_MAP[type]
        command_class.new(**args)
      end
    end
  end
end
