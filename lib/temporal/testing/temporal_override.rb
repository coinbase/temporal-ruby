require 'securerandom'
require 'temporal/activity/async_token'
require 'temporal/workflow/execution_info'
require 'temporal/testing/workflow_execution'
require 'temporal/testing/local_workflow_context'

module Temporal
  module Testing
    module TemporalOverride

      def start_workflow(workflow, *input, **args)
        return super if Temporal::Testing.disabled?

        if Temporal::Testing.local?
          start_locally(workflow, nil, *input, **args)
        end
      end

      # We don't support testing the actual cron schedules, but we will defer 
      # execution.  You can simulate running these deferred with run_all_scheduled_workflows or 
      # run_scheduled_workflow, or assert against the cron schedule with schedules.
      def schedule_workflow(workflow, cron_schedule, *input, **args)
        return super if Temporal::Testing.disabled?

        if Temporal::Testing.local?
          start_locally(workflow, cron_schedule, *input, **args)
        end
      end

      def fetch_workflow_execution_info(_namespace, workflow_id, run_id)
        return super if Temporal::Testing.disabled?

        execution = executions[[workflow_id, run_id]]

        Workflow::ExecutionInfo.new(
          workflow: nil,
          workflow_id: workflow_id,
          run_id: run_id,
          start_time: nil,
          close_time: nil,
          status: execution.status,
          history_length: nil,
        ).freeze
      end

      def complete_activity(async_token, result = nil)
        return super if Temporal::Testing.disabled?

        details = Activity::AsyncToken.decode(async_token)
        execution = executions[[details.workflow_id, details.run_id]]

        execution.complete_activity(async_token, result)
      end

      def fail_activity(async_token, exception)
        return super if Temporal::Testing.disabled?

        details = Activity::AsyncToken.decode(async_token)
        execution = executions[[details.workflow_id, details.run_id]]

        execution.fail_activity(async_token, exception)
      end

      def run_scheduled_workflow(workflow_id:)
        unless scheduled_executions.key?(workflow_id)
          raise Temporal::Testing::WorkflowIDNotScheduled,
            "There is no workflow with id #{workflow_id} that was scheduled with Temporal.schedule_workflow.\n"\
            "Options: #{scheduled_executions.keys}"
        end

        scheduled_executions[workflow_id].call
      end

      def run_all_scheduled_workflows
        scheduled_executions.transform_values(&:call)
      end
      
      # Populated by schedule_workflow
      # format: { <workflow_id>: <cron schedule string>, ... }
      def schedules
        @schedules ||= {}
      end

      private

      def executions
        @executions ||= {}
      end

      def scheduled_executions
        @scheduled_executions ||= {}
      end


      def start_locally(workflow, schedule, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        reuse_policy = options[:workflow_id_reuse_policy] || :allow_failed
        workflow_id = options[:workflow_id] || SecureRandom.uuid
        run_id = SecureRandom.uuid

        if !allowed?(workflow_id, reuse_policy)
          raise Temporal::WorkflowExecutionAlreadyStartedFailure.new(
            "Workflow execution already started for id #{workflow_id}, reuse policy #{reuse_policy}",
            previous_run_id(workflow_id)
          )  
        end

        execution = WorkflowExecution.new
        executions[[workflow_id, run_id]] = execution

        execution_options = ExecutionOptions.new(workflow, options)
        headers = execution_options.headers
        context = Temporal::Testing::LocalWorkflowContext.new(
          execution, workflow_id, run_id, workflow.disabled_releases, headers
        )

        if schedule.nil?
          execution.run do
            workflow.execute_in_context(context, input)
          end
        else
          # Defer execution; in testing mode, it'll need to be invoked manually.
          schedules[workflow_id] = schedule # In case someone wants to assert the schedule is what they expect
          scheduled_executions[workflow_id] = lambda do
            execution.run do
              workflow.execute_in_context(context, input)
            end
          end
        end
        run_id
      end

      def allowed?(workflow_id, reuse_policy)
        disallowed_statuses = disallowed_statuses_for(reuse_policy)

        # there isn't a single execution in a dissallowed status
        executions.none? do |(w_id, _), execution|
          w_id == workflow_id && disallowed_statuses.include?(execution.status)
        end
      end

      def previous_run_id(workflow_id)
        executions.each do |(w_id, run_id), _|
          return run_id if w_id == workflow_id
        end
        nil
      end

      def disallowed_statuses_for(reuse_policy)
        case reuse_policy
        when :allow_failed
          [Workflow::ExecutionInfo::RUNNING_STATUS, Workflow::ExecutionInfo::COMPLETED_STATUS]
        when :allow
          [Workflow::ExecutionInfo::RUNNING_STATUS]
        when :reject
          [
            Workflow::ExecutionInfo::RUNNING_STATUS,
            Workflow::ExecutionInfo::FAILED_STATUS,
            Workflow::ExecutionInfo::COMPLETED_STATUS
          ]
        end
      end
    end
  end
end
