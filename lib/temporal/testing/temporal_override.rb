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
          start_locally(workflow, *input, **args)
        end
      end

      def fetch_workflow_execution_info(_domain, workflow_id, run_id)
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

      def fail_activity(async_token, error)
        return super if Temporal::Testing.disabled?

        details = Activity::AsyncToken.decode(async_token)
        execution = executions[[details.workflow_id, details.run_id]]

        execution.fail_activity(async_token, error)
      end

      private

      def executions
        @executions ||= {}
      end

      def start_locally(workflow, *input, **args)
        options = args.delete(:options) || {}
        input << args unless args.empty?

        reuse_policy = options[:workflow_id_reuse_policy] || :allow_failed
        workflow_id = options[:workflow_id] || SecureRandom.uuid
        run_id = SecureRandom.uuid

        if !allowed?(workflow_id, reuse_policy)
          raise TemporalThrift::WorkflowExecutionAlreadyStartedError,
            "Workflow execution already started for id #{workflow_id}, reuse policy #{reuse_policy}"
        end

        execution = WorkflowExecution.new
        executions[[workflow_id, run_id]] = execution

        execution_options = ExecutionOptions.new(workflow, options)
        headers = execution_options.headers
        context = Temporal::Testing::LocalWorkflowContext.new(
          execution, workflow_id, run_id, workflow.disabled_releases, headers
        )

        execution.run do
          workflow.execute_in_context(context, input)
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
