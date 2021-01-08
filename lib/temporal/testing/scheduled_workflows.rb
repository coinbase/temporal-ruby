module Temporal
  module Testing
    class WorkflowIDNotScheduled < ClientError; end

    # Implementation for Temporal::Testing::ScheduledWorkflwows
    module ScheduledWorkflowsImpl
      class << self

        # For someone who wants to assert that the schedule is what they expect.
        # Populated by Temporal.schedule_workflow
        # format: { <workflow_id>: <cron schedule string>, ... }
        def schedules
          _schedules.dup.freeze
        end

        def add(workflow_id:, cron_schedule:, executor_lambda:)
          _schedules[workflow_id] = cron_schedule
          _scheduled_executions[workflow_id] = executor_lambda
        end

        private def _schedules
          @schedules ||= {}
        end

        private def _scheduled_executions
          @scheduled_executions ||= {}
        end

        # Populated by Temporal.schedule_workflow
        def scheduled_executions
          _scheduled_executions.dup.freeze
        end

        def clear_all
          @scheduled_executions = {}
          @schedules = {}
        end

        def execute(workflow_id:)
          unless _scheduled_executions.key?(workflow_id)
            raise Temporal::Testing::WorkflowIDNotScheduled,
              "There is no workflow with id #{workflow_id} that was scheduled with Temporal.schedule_workflow.\n"\
              "Options: #{_scheduled_executions.keys}"
          end

          _scheduled_executions[workflow_id].call
        end

        def execute_all
          _scheduled_executions.transform_values(&:call)
        end
      end
    end
  end
end
