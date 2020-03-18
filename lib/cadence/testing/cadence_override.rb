require 'securerandom'
require 'cadence/testing/local_workflow_context'

module Cadence
  module Testing
    module CadenceOverride
      def start_workflow(workflow, *input, **args)
        if Cadence::Testing.disabled?
          super
        elsif Cadence::Testing.local?
          start_locally(workflow, *input, **args)
        end
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

        if !allowed?(workflow_id, reuse_policy)
          raise CadenceThrift::WorkflowExecutionAlreadyStartedError,
            "Workflow execution already started for id #{workflow_id}, reuse policy #{reuse_policy}"
        end

        executions[workflow_id] = :started

        context = Cadence::Testing::LocalWorkflowContext.new(workflow_id)

        begin
          workflow.execute_in_context(context, input).tap do
            executions[workflow_id] = :completed
          end
        rescue StandardError
          executions[workflow_id] = :failed
          raise
        end
      end

      def allowed?(workflow_id, reuse_policy)
        !disallowed_statuses_for(reuse_policy).include?(executions[workflow_id])
      end

      def disallowed_statuses_for(reuse_policy)
        case reuse_policy
        when :allow_failed
          [:started, :completed]
        when :allow
          [:started]
        when :reject
          [:started, :failed, :completed]
        end
      end
    end
  end
end
