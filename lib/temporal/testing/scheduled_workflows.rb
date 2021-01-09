module Temporal
  module Testing
    class WorkflowIDNotScheduled < ClientError; end

    # When Temporal.schedule_workflow is called in a test in local mode, we defer the execution and do
    # not do it automatically.
    # You can execute them or inspect their cron schedules using this module.
    module ScheduledWorkflows
      def self.execute(workflow_id:)
        Private::Store.execute(workflow_id: workflow_id)
      end

      def self.execute_all
        Private::Store.execute_all
      end

      # For someone who wants to assert that the schedule is what they expect.
      # Populated by Temporal.schedule_workflow
      # format: { <workflow_id>: <cron schedule string>, ... }
      def self.cron_schedules
        Private::Store.schedules
      end

      def self.clear_all
        Private::Store.clear_all
      end

      module Private
        module Store
          class << self

            def schedules
              @schedules ||= {}.freeze
            end

            def add(workflow_id:, cron_schedule:, executor_lambda:)
              new_schedules = schedules.dup
              new_schedules[workflow_id] = cron_schedule
              @schedules = new_schedules.freeze

              new_scheduled_executions = scheduled_executions.dup
              new_scheduled_executions[workflow_id] = executor_lambda
              @scheduled_executions = new_scheduled_executions.freeze
            end

            def clear_all
              @scheduled_executions = {}.freeze
              @schedules = {}.freeze
            end

            def execute(workflow_id:)
              unless scheduled_executions.key?(workflow_id)
                raise Temporal::Testing::WorkflowIDNotScheduled,
                "There is no workflow with id #{workflow_id} that was scheduled with Temporal.schedule_workflow.\n"\
                "Options: #{scheduled_executions.keys}"
              end

              scheduled_executions[workflow_id].call
            end

            def execute_all
              scheduled_executions.values.each(&:call)
            end

            private

            def scheduled_executions
              @scheduled_executions ||= {}.freeze
            end
          end
        end
      end
    end
  end
end
