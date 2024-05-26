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
        # Duplicate the configuration so that this doesn't interfere with other tests in the
        # same process that are not replay tests
        @config = config.dup.tap do |c|
          # Log on replay during replay tests so that more context is available workflow execution
          c.log_on_workflow_replay = true
        end
      end

      # Runs a replay test by loading a file from the given file path that contains JSON. This JSON can be
      # downloaded using the .get_workflow_history_json method on the Temporal client, through the Temporal CLI,
      # or the Temporal UI.
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      #
      # Common problems and solutions:
      # - "Unexpected event UNSPECIFIED". This can occur if the history was downloaded with Java-style enum values, which
      #   can happen in certain versions of certain SDKs. USe the correct_event_types function below to convert these.
      #   See that function's comment for more details.
      def replay_history_json_file(workflow_class, path)
        json = File.read(path)
        raw_history = Temporalio::Api::History::V1::History.decode_json(json, ignore_unknown_fields: true)
        replay_history(workflow_class, Workflow::History.new(raw_history.events))
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
        protobuf = File.open(path, "rb") do |f|
          f.read
        end

        replay_history_protobuf(workflow_class, protobuf)
      end

      # Runs a replay test binary using a protobuf string
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      def replay_history_protobuf(workflow_class, proto)
        raw_history = Temporalio::Api::History::V1::History.decode(proto)
        replay_history(workflow_class, Workflow::History.new(raw_history.events))
      end

      # Runs a replay test by using the specifiec Temporal::Workflow::History object. This can only be obtained by
      # calling the .get_workflow_history method on the Temporal client to download a history from Temporal server
      # into memory.
      #
      # If the replay test succeeds, the method will return silently. If the replay tests fails, an error will be raised.
      def replay_history(workflow_class, history)
        # This code roughly resembles the workflow TaskProcessor but with history being fed in rather
        # than being pulled via a workflow task, no query support, no metrics, and other
        # simplifications. Fake metadata needs to be provided.
        metadata = Temporal::Metadata::WorkflowTask.new(
          namespace: "replay-test",
          id: 1,
          task_token: "",
          attempt: 1,
          workflow_run_id: "run_id",
          workflow_id: "workflow_id",
          workflow_name: history.find_event_by_id(1).attributes.workflow_type.name
        )

        executor = Workflow::Executor.new(
          workflow_class,
          history,
          metadata,
          @config,
          true,
          Middleware::Chain.new([])
        )

        run_result = begin
          executor.run
        rescue => e
          query = Struct.new(:query_type, :query_args).new(
            Temporal::Workflow::StackTraceTracker::STACK_TRACE_QUERY_NAME,
            nil
          )
          query_result = executor.process_queries(
            {"stack_trace" => query}
          )
          # Override the stack trace to the point in the workflow code where the failure occured, not the
          # point in the StateManager where non-determinism is detected
          e.set_backtrace(query_result["stack_trace"].result)
          raise ReplayError, e
        end

        if run_result.commands.any?
          raise ReplayError, "Workflow task is issuing new commands when it should complete: #{run_result.commands}"
        end
      end

      # Protobuf does not define a consistent format for enums in JSON. In some Temporal SDKs, the event
      # type enum takes the form 'WorkflowTaskScheduled' but here it needs to be EVENT_TYPE_WORKFLOW_TASK_SCHEDULED.
      # This code parses the JSON, reformats these fields, then regenerates the JSON. This should not be necessary
      # for histories downloaded from recent versions of the Temporal CLI, Temporal UI, or using methods
      # on Temporal::Client.
      #
      # If the pretty_print optional parameter is set to true, it outputs in a more human
      # readable form on output.
      def self.correct_event_types(text, pretty_print: true)
        json_hash = ::JSON.parse(text)
        json_hash["events"].each do |event|
          if !event["eventType"].start_with?("EVENT_TYPE")
            event["eventType"] = "EVENT_TYPE_" + event["eventType"].gsub(/(.)([A-Z])/, "\\1_\\2").upcase
          end
        end

        if pretty_print
          ::JSON.pretty_generate(json_hash)
        else
          ::JSON.generate(json_hash)
        end
      end
    end
  end
end
