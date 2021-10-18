require 'securerandom'
require 'set'
require 'temporal/testing/local_workflow_context'
require 'temporal/testing/workflow_execution'
require 'temporal/metadata/workflow'

module Temporal
  module Testing
    module WorkflowOverride
      def disabled_releases
        @disabled_releases ||= Set.new
      end

      def allow_all_releases
        disabled_releases.clear
      end

      def allow_release(release_name)
        disabled_releases.delete(release_name.to_s)
      end

      def disable_release(release_name)
        disabled_releases << release_name.to_s
      end

      def execute_locally(*input)
        workflow_id = SecureRandom.uuid
        run_id = SecureRandom.uuid
        execution = WorkflowExecution.new
        metadata = Temporal::Metadata::Workflow.new(
          name: workflow_id,
          workflow_id: workflow_id,
          run_id: run_id,
          attempt: 1,
          namespace: 'unit-test-local',
          task_queue: 'unit-test-task-queue',
          memo: {},
          headers: {},
        )
        context = Temporal::Testing::LocalWorkflowContext.new(
          execution, workflow_id, run_id, disabled_releases, metadata
        )

        execute_in_context(context, input)
      end
    end
  end
end
