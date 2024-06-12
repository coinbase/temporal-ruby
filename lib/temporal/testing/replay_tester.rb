require 'gen/temporal/api/history/v1/message_pb'
require 'json'
require 'temporal/errors'
require 'temporal/metadata/workflow_task'
require 'temporal/middleware/chain'
require 'temporal/workflow/executor'
require 'temporal/workflow/stack_trace_tracker'

module Temporal
  module Testing
    class ReplayError < StandardError
    end

    class ReplayTester
      def initialize(config: Temporal.configuration)
        @config = config
      end

      # Runs a replay test by loading a file from the given file path that contains JSON. This JSON can be
      # downloaded using the .get_workflow_history_json method on the Temporal client, through the Temporal CLI,
      # or the Temporal UI.
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      #
      # Common problems and solutions:
      # - "Unexpected event UNSPECIFIED". This can occur if the history was downloaded with Java-style enum values, which
      #   can happen in certain versions of certain SDKs. Use the correct_event_types function below to convert these.
      #   See that function's comment for more details.
      def replay_history_json_file(workflow_class, path)
        json = File.read(path)
        replay_history_json(workflow_class, json)
      end

      # Runs a replay test on a JSON string directly. See comment on replay_history_json_file more details.
      def replay_history_json(workflow_class, json)
        raw_history = Temporalio::Api::History::V1::History.decode_json(json, ignore_unknown_fields: true)
        replay_history(workflow_class, Workflow::History.new(raw_history.events))
      end

      # Runs a replay test by loading a file from the given file path that contains protobuf binary. This can
      # be downloaded usin the .get_workflow_history_protobuf method on the Temporal client or possibly through
      # the use of third party tools like grpcurl.
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      #
      # IMPORTANT: This file is a binary file, not a text file. The protobuf obtained from get_workflow_history_protobuf
      # must be written using binary file options.
      def replay_history_protobuf_file(workflow_class, path)
        protobuf = File.open(path, 'rb', &:read)
        replay_history_protobuf(workflow_class, protobuf)
      end

      # Runs a replay test binary using a protobuf string
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      def replay_history_protobuf(workflow_class, proto)
        raw_history = Temporalio::Api::History::V1::History.decode(proto)
        replay_history(workflow_class, Workflow::History.new(raw_history.events))
      end

      # Runs a replay test by using the specific Temporal::Workflow::History object. This can only be obtained by
      # calling the .get_workflow_history method on the Temporal client to download a history from Temporal server
      # into memory.
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
          namespace: 'replay-test',
          id: 1,
          task_token: '',
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
          @config,
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
            { 'stack_trace' => query }
          )
          replay_error = ReplayError.new('Workflow code failed to replay successfully against history')
          # Override the stack trace to the point in the workflow code where the failure occured, not the
          # point in the StateManager where non-determinism is detected
          replay_error.set_backtrace("Fiber backtraces: #{query_result['stack_trace'].result}")
          raise replay_error
        end
      end
    end
  end
end