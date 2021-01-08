require 'temporal/testing/temporal_override'
require 'temporal/testing/workflow_override'
require 'temporal/testing/scheduled_workflows'

module Temporal
  module Testing
    DISABLED_MODE = nil
    LOCAL_MODE = :local

    class << self
      def local!(&block)
        set_mode(LOCAL_MODE, &block)
      end

      def disabled!(&block)
        set_mode(DISABLED_MODE, &block)
      end

      def disabled?
        mode == DISABLED_MODE
      end

      def local?
        mode == LOCAL_MODE
      end

      private

      attr_reader :mode

      def set_mode(new_mode, &block)
        if block_given?
          with_mode(new_mode, &block)
        else
          @mode = new_mode
        end
      end

      def with_mode(new_mode, &block)
        previous_mode = mode
        @mode = new_mode
        yield
      ensure
        @mode = previous_mode
      end
    end

    # When Temporal.schedule_workflow is called in a test in local mode, we defer the execution and do
    # not do it automatically.
    # You can execute them or inspect their cron schedules using this module.
    module ScheduledWorkflows
      def self.execute(workflow_id:)
        Temporal::Testing::ScheduledWorkflowsImpl.execute(workflow_id: workflow_id)
      end

      def self.execute_all
        Temporal::Testing::ScheduledWorkflowsImpl.execute_all
      end

      # format: { <workflow_id>: <cron schedule string>, ... }
      def self.cron_schedules
        Temporal::Testing::ScheduledWorkflowsImpl.schedules
      end

      def self.clear_all
        Temporal::Testing::ScheduledWorkflowsImpl.clear_all
      end
    end
  end
end

Temporal.singleton_class.prepend Temporal::Testing::TemporalOverride
Temporal::Workflow.extend Temporal::Testing::WorkflowOverride
