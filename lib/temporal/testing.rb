require 'temporal/testing/temporal_override'
require 'temporal/testing/workflow_override'

module Temporal
  module Testing
    DISABLED_MODE = nil
    LOCAL_MODE = :local

    class WorkflowIDNotScheduled < ClientError; end

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

      def execute_scheduled_workflow(workflow_id:)
        unless scheduled_executions.key?(workflow_id)
          raise Temporal::Testing::WorkflowIDNotScheduled,
            "There is no workflow with id #{workflow_id} that was scheduled with Temporal.schedule_workflow.\n"\
            "Options: #{scheduled_executions.keys}"
        end

        scheduled_executions[workflow_id].call
      end

      def execute_all_scheduled_workflows
        scheduled_executions.transform_values(&:call)
      end

      # Populated by Temporal.schedule_workflow
      # format: { <workflow_id>: <cron schedule string>, ... }
      def schedules
        @schedules ||= {}
      end

      # Populated by Temporal.schedule_workflow
      def scheduled_executions
        @scheduled_executions ||= {}
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
  end
end

Temporal.singleton_class.prepend Temporal::Testing::TemporalOverride
Temporal::Workflow.extend Temporal::Testing::WorkflowOverride
