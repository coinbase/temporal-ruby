require "forwardable"

module Temporal
  module Schedule
    class StartWorkflowAction
      extend Forwardable

      #target
      def_delegators(
        :@execution_options,
        :name,
        :task_queue,
        :headers,
        :memo
      )

      attr_reader :workflow_id, :input

      # @param workflow [Temporal::Workflow, String] workflow class or name. When a workflow class
      #   is passed, its config (namespace, task_queue, timeouts, etc) will be used
      # @param input [any] arguments to be passed to workflow's #execute method
      # @param args [Hash] keyword arguments to be passed to workflow's #execute method
      # @param options [Hash, nil] optional overrides
      # @option options [String] :workflow_id
      # @option options [String] :name workflow name
      # @option options [String] :namespace
      # @option options [String] :task_queue
      # @option options [Hash] :retry_policy check Temporal::RetryPolicy for available options
      # @option options [Hash] :timeouts check Temporal::Configuration::DEFAULT_TIMEOUTS
      # @option options [Hash] :headers
      # @option options [Hash] :search_attributes
      #
      # @return [String] workflow's run ID
      def initialize(workflow, *input, options: {})
        @workflow_id = options[:workflow_id] || SecureRandom.uuid
        @input = input

        @execution_options = ExecutionOptions.new(workflow, options)
      end

      def execution_timeout
        @execution_options.timeouts[:execution]
      end

      def run_timeout
        @execution_options.timeouts[:run] || @execution_options.timeouts[:execution]
      end

      def task_timeout
        @execution_options.timeouts[:task]
      end

      def search_attributes
        Workflow::Context::Helpers.process_search_attributes(@execution_options.search_attributes)
      end
    end
  end
end
