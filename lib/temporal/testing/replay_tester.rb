require "gen/temporal/api/history/v1/message_pb"
require "json"
require "temporal/errors"
require "temporal/metadata/workflow_task"
require "temporal/middleware/chain"
require "temporal/workflow/executor"
require "temporal/workflow/stack_trace_tracker"

module Temporal
  module Testing
    class ReplayError < StandardError
    end

    class ReplayTester
      def initialize(config: Temporal.configuration)
        @config = config
      end

      attr_reader :config

      # Runs a replay test by using the specific Temporal::Workflow::History object. Instances of these objects
      # can be obtained using various from_ methods in Temporal::Workflow::History::Serialization.
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      def replay_history(workflow_class, history)
        # This code roughly resembles the workflow TaskProcessor but with history being fed in rather
        # than being pulled via a workflow task, no query support, no metrics, and other
        # simplifications. Fake metadata needs to be provided.
        start_workflow_event = history.find_event_by_id(1)
        if start_workflow_event.nil? || start_workflow_event.type != "WORKFLOW_EXECUTION_STARTED"
          raise ReplayError, "History does not start with workflow_execution_started event"
        end

        metadata = Temporal::Metadata::WorkflowTask.new(
          namespace: config.namespace,
          id: 1,
          task_token: "",
          attempt: 1,
          workflow_run_id: "run_id",
          workflow_id: "workflow_id",
          # Protobuf deserialization will ensure this tree is present
          workflow_name: start_workflow_event.attributes.workflow_type.name
        )

        executor = Workflow::Executor.new(
          workflow_class,
          history,
          metadata,
          config,
          true,
          Middleware::Chain.new([])
        )

        begin
          executor.run
        rescue StandardError
          query = Struct.new(:query_type, :query_args).new(
            Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME,
            nil
          )
          query_result = executor.process_queries(
            {"stack_trace" => query}
          )
          replay_error = ReplayError.new("Workflow code failed to replay successfully against history")
          # Override the stack trace to the point in the workflow code where the failure occured, not the
          # point in the StateManager where non-determinism is detected
          replay_error.set_backtrace("Fiber backtraces: #{query_result["stack_trace"].result}")
          raise replay_error
        end
      end
    end
  end
end
