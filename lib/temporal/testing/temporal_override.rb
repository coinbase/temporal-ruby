require 'securerandom'
require 'temporal/activity/async_token'
require 'temporal/workflow/execution_info'
require 'temporal/testing/workflow_execution'
require 'temporal/testing/local_workflow_context'

module Temporal
  module Testing
    module TemporalOverride

      def start_workflow(workflow, *input, signal_name: nil, signal_input: nil, **args)
        return super if Temporal::Testing.disabled?

        if Temporal::Testing.local?
          # signals aren't supported at all, so let's prohibit start_workflow calls that try to signal
          raise NotImplementedError, 'Signals are not available when Temporal::Testing.local! is on' unless signal_name.nil? && signal_input.nil?
          start_locally(workflow, nil, *input, **args)
        end
      end

      # We don't support testing the actual cron schedules, but we will defer
      # execution.  You can simulate running these deferred with
      # Temporal::Testing.execute_all_scheduled_workflows o
      # Temporal::Testing.execute_scheduled_workflow, or assert against the cron schedule with
      # Temporal::Testing.schedules.
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

      private

      def executions
        @executions ||= {}
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
        metadata = Metadata::Workflow.new(
          namespace: execution_options.namespace,
          id: workflow_id,
          name: execution_options.name,
          run_id: run_id,
          attempt: 1,
          headers: execution_options.headers
        )
        context = Temporal::Testing::LocalWorkflowContext.new(
          execution, workflow_id, run_id, workflow.disabled_releases, metadata
        )

        if schedule.nil?
          execution.run do
            workflow.execute_in_context(context, input)
          end
        else
          # Defer execution; in testing mode, it'll need to be invoked manually.
          Temporal::Testing::ScheduledWorkflows::Private::Store.add(
            workflow_id: workflow_id,
            cron_schedule: schedule,
            executor_lambda: lambda do
              execution.run do
                workflow.execute_in_context(context, input)
              end
            end,
          )
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
