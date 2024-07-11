require 'json'
require 'temporal/execution_options'
require 'temporal/connection'
require 'temporal/activity'
require 'temporal/activity/async_token'
require 'temporal/workflow'
require 'temporal/workflow/context_helpers'
require 'temporal/workflow/history'
require 'temporal/workflow/history/serialization'
require 'temporal/workflow/execution_info'
require 'temporal/workflow/executions'
require 'temporal/workflow/status'
require 'temporal/reset_strategy'

module Temporal
  class Client
    def initialize(config)
      @config = config
    end

    # Start a workflow with an optional signal
    #
    # If options[:signal_name] is specified, Temporal will atomically start a new workflow and
    # signal it or signal a running workflow (matching a specified options[:workflow_id])
    #
    # @param workflow [Temporal::Workflow, String] workflow class or name. When a workflow class
    #   is passed, its config (namespace, task_queue, timeouts, etc) will be used
    # @param input [any] arguments to be passed to workflow's #execute method
    # @param args [Hash] keyword arguments to be passed to workflow's #execute method
    # @param options [Hash, nil] optional overrides
    # @option options [String] :workflow_id
    # @option options [Symbol] :workflow_id_reuse_policy check Temporal::Connection::GRPC::WORKFLOW_ID_REUSE_POLICY
    # @option options [String] :name workflow name
    # @option options [String] :namespace
    # @option options [String] :task_queue
    # @option options [String] :signal_name corresponds to the 'signal' argument to signal_workflow. Required if
    #   options[:signal_input] is specified.
    # @option options [String, Array, nil] :signal_input corresponds to the 'input' argument to signal_workflow
    # @option options [Hash] :retry_policy check Temporal::RetryPolicy for available options
    # @option options [Hash] :timeouts check Temporal::Configuration::DEFAULT_TIMEOUTS
    # @option options [Hash] :headers
    # @option options [Hash] :search_attributes
    #
    # @return [String] workflow's run ID
    def start_workflow(workflow, *input, options: {}, **args)
      input << args unless args.empty?

      signal_name = options.delete(:signal_name)
      signal_input = options.delete(:signal_input)

      execution_options = ExecutionOptions.new(workflow, options, config.default_execution_options)
      workflow_id = options[:workflow_id] || SecureRandom.uuid

      if signal_name.nil? && signal_input.nil?
        response = connection.start_workflow_execution(
          namespace: execution_options.namespace,
          workflow_id: workflow_id,
          workflow_name: execution_options.name,
          task_queue: execution_options.task_queue,
          input: input,
          execution_timeout: execution_options.timeouts[:execution],
          # If unspecified, individual runs should have the full time for the execution (which includes retries).
          run_timeout: compute_run_timeout(execution_options),
          task_timeout: execution_options.timeouts[:task],
          workflow_id_reuse_policy: options[:workflow_id_reuse_policy],
          headers: config.header_propagator_chain.inject(execution_options.headers),
          memo: execution_options.memo,
          search_attributes: Workflow::Context::Helpers.process_search_attributes(execution_options.search_attributes),
        )
      else
        raise ArgumentError, 'If signal_input is provided, you must also provide signal_name' if signal_name.nil?

        response = connection.signal_with_start_workflow_execution(
          namespace: execution_options.namespace,
          workflow_id: workflow_id,
          workflow_name: execution_options.name,
          task_queue: execution_options.task_queue,
          input: input,
          execution_timeout: execution_options.timeouts[:execution],
          run_timeout: compute_run_timeout(execution_options),
          task_timeout: execution_options.timeouts[:task],
          workflow_id_reuse_policy: options[:workflow_id_reuse_policy],
          headers: config.header_propagator_chain.inject(execution_options.headers),
          memo: execution_options.memo,
          search_attributes: Workflow::Context::Helpers.process_search_attributes(execution_options.search_attributes),
          signal_name: signal_name,
          signal_input: signal_input
        )
      end

      response.run_id
    end

    # Schedule a workflow for a periodic cron-like execution
    #
    # @param workflow [Temporal::Workflow, String] workflow class or name. When a workflow class
    #   is passed, its config (namespace, task_queue, timeouts, etc) will be used
    # @param cron_schedule [String] a cron-style schedule string
    # @param input [any] arguments to be passed to workflow's #execute method
    # @param args [Hash] keyword arguments to be pass to workflow's #execute method
    # @param options [Hash, nil] optional overrides
    # @option options [String] :workflow_id
    # @option options [Symbol] :workflow_id_reuse_policy check Temporal::Connection::GRPC::WORKFLOW_ID_REUSE_POLICY
    # @option options [String] :name workflow name
    # @option options [String] :namespace
    # @option options [String] :task_queue
    # @option options [Hash] :retry_policy check Temporal::RetryPolicy for available options
    # @option options [Hash] :timeouts check Temporal::Configuration::DEFAULT_TIMEOUTS
    # @option options [Hash] :headers
    # @option options [Hash] :search_attributes
    #
    # @return [String] workflow's run ID
    def schedule_workflow(workflow, cron_schedule, *input, options: {}, **args)
      input << args unless args.empty?

      execution_options = ExecutionOptions.new(workflow, options, config.default_execution_options)
      workflow_id = options[:workflow_id] || SecureRandom.uuid

      response = connection.start_workflow_execution(
        namespace: execution_options.namespace,
        workflow_id: workflow_id,
        workflow_name: execution_options.name,
        task_queue: execution_options.task_queue,
        input: input,
        execution_timeout: execution_options.timeouts[:execution],
        # Execution timeout is across all scheduled jobs, whereas run is for an individual run.
        # This default is here for backward compatibility.  Certainly, the run timeout shouldn't be higher
        # than the execution timeout.
        run_timeout: compute_run_timeout(execution_options),
        task_timeout: execution_options.timeouts[:task],
        workflow_id_reuse_policy: options[:workflow_id_reuse_policy],
        headers: config.header_propagator_chain.inject(execution_options.headers),
        cron_schedule: cron_schedule,
        memo: execution_options.memo,
        search_attributes: Workflow::Context::Helpers.process_search_attributes(execution_options.search_attributes),
      )

      response.run_id
    end

    # Register a new Temporal namespace
    #
    # @param name [String] name of the new namespace
    # @param description [String] optional namespace description
    # @param is_global [Boolean] used to distinguish local namespaces from global namespaces (https://docs.temporal.io/docs/server/namespaces/#global-namespaces)
    # @param retention_period [Int] optional value which specifies how long Temporal will keep workflows after completing
    # @param data [Hash] optional key-value map for any customized purpose that can be retreived with describe_namespace
    def register_namespace(name, description = nil, is_global: false, retention_period: 10, data: nil)
      connection.register_namespace(name: name, description: description, is_global: is_global, retention_period: retention_period, data: data)
    end

    # Fetches metadata for a namespace.
    # @param name [String] name of the namespace
    # @return [Hash] info deserialized from Temporalio::Api::WorkflowService::V1::DescribeNamespaceResponse
    def describe_namespace(name)
      connection.describe_namespace(name: name)
    end

    # Fetches all the namespaces.
    #
    # @param page_size [Integer] number of namespace results to return per page.
    # @param next_page_token [String] a optional pagination token returned by a previous list_namespaces call
    def list_namespaces(page_size:, next_page_token: "")
      connection.list_namespaces(page_size: page_size, next_page_token: next_page_token)
    end

    # Send a signal to a running workflow
    #
    # @param workflow [Temporal::Workflow, nil] workflow class or nil
    # @param signal [String] name of the signal to send
    # @param workflow_id [String]
    # @param run_id [String]
    # @param input [String, Array, nil] optional arguments for the signal
    # @param namespace [String, nil] if nil, choose the one declared on the workflow class or the
    #   global default
    def signal_workflow(workflow, signal, workflow_id, run_id, input = nil, namespace: nil)
      execution_options = ExecutionOptions.new(workflow, {}, config.default_execution_options)

      connection.signal_workflow_execution(
        namespace: namespace || execution_options.namespace,
        workflow_id: workflow_id,
        run_id: run_id,
        signal: signal,
        input: input
      )
    end

    # Issue a query against a running workflow
    #
    # @param workflow [Temporal::Workflow, nil] workflow class or nil
    # @param query [String] name of the query to issue
    # @param workflow_id [String]
    # @param run_id [String]
    # @param args [String, Array, nil] optional arguments for the query
    # @param namespace [String, nil] if nil, choose the one declared on the workflow class or the
    #   global default
    # @param query_reject_condition [Symbol] check Temporal::Connection::GRPC::QUERY_REJECT_CONDITION
    def query_workflow(workflow, query, workflow_id, run_id, *args, namespace: nil, query_reject_condition: nil)
      execution_options = ExecutionOptions.new(workflow, {}, config.default_execution_options)

      connection.query_workflow(
        namespace: namespace || execution_options.namespace,
        workflow_id: workflow_id,
        run_id: run_id,
        query: query,
        args: args,
        query_reject_condition: query_reject_condition
      )
    end

    # Long polls for a workflow to be completed and returns workflow's return value.
    #
    # @note This function times out after 30 seconds and throws Temporal::TimeoutError,
    #   not to be confused with `Temporal::WorkflowTimedOut` which reports that the workflow
    #   itself timed out.
    #
    # @param workflow [Temporal::Workflow, nil] workflow class or nil
    # @param workflow_id [String]
    # @param run_id [String, nil] awaits the entire workflow completion when nil. This can span
    #   multiple runs in the case where the workflow uses continue-as-new.
    # @param timeout [Integer, nil] seconds to wait for the result. This cannot be longer than 30
    #   seconds because that is the maximum the server supports.
    # @param namespace [String, nil] if nil, choose the one declared on the workflow class or the
    #   global default
    #
    # @return workflow's return value
    def await_workflow_result(workflow, workflow_id:, run_id: nil, timeout: nil, namespace: nil)
      options = namespace ? {namespace: namespace} : {}
      execution_options = ExecutionOptions.new(workflow, options, config.default_execution_options)
      max_timeout = Temporal::Connection::GRPC::SERVER_MAX_GET_WORKFLOW_EXECUTION_HISTORY_POLL
      history_response = nil
      loop do
        begin
          history_response = connection.get_workflow_execution_history(
            namespace: execution_options.namespace,
            workflow_id: workflow_id,
            run_id: run_id,
            wait_for_new_event: true,
            event_type: :close,
            timeout: timeout || max_timeout,
          )
        rescue GRPC::DeadlineExceeded => e
          message = if timeout
            "Timed out after your specified limit of timeout: #{timeout} seconds"
          else
            "Timed out after #{max_timeout} seconds, which is the maximum supported amount."
          end
          raise TimeoutError.new(message)
        end
        history = Workflow::History.new(history_response.history.events)
        closed_event = history.events.first

        break if closed_event
      end
      case closed_event.type
      when 'WORKFLOW_EXECUTION_COMPLETED'
        payloads = closed_event.attributes.result
        return ResultConverter.from_result_payloads(payloads)
      when 'WORKFLOW_EXECUTION_TIMED_OUT'
        raise Temporal::WorkflowTimedOut
      when 'WORKFLOW_EXECUTION_TERMINATED'
        raise Temporal::WorkflowTerminated
      when 'WORKFLOW_EXECUTION_CANCELED'
        raise Temporal::WorkflowCanceled
      when 'WORKFLOW_EXECUTION_FAILED'
        raise Temporal::Workflow::Errors.generate_error(closed_event.attributes.failure)
      when 'WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
        new_run_id = closed_event.attributes.new_execution_run_id
        # Throw to let the caller know they're not getting the result
        # they wanted.  They can re-call with the new run_id to poll.
        raise Temporal::WorkflowRunContinuedAsNew.new(new_run_id: new_run_id)
      else
        raise NotImplementedError, "Unexpected event type #{closed_event.type}."
      end
    end

    # Reset a workflow
    #
    # @note More on resetting a workflow here —
    #   https://docs.temporal.io/tctl-v1/workflow#reset
    #
    # @param namespace [String]
    # @param workflow_id [String]
    # @param run_id [String]
    # @param strategy [Symbol, nil] one of the Temporal::ResetStrategy values or `nil` when
    #   passing a workflow_task_id
    # @param workflow_task_id [Integer, nil] A specific event ID to reset to. The event has to
    #   be of a type WorkflowTaskCompleted, WorkflowTaskFailed or WorkflowTaskTimedOut
    # @param reason [String] a reset reason to be recorded in workflow's history for reference
    # @param request_id [String, nil] an idempotency key for the Reset request or `nil` to use
    #   an auto-generated, unique value
    # @param reset_reapply_type [Symbol] one of the Temporal::ResetReapplyType values. Defaults
    #   to SIGNAL.
    #
    # @return [String] run_id of the new workflow execution
    def reset_workflow(namespace, workflow_id, run_id, strategy: nil, workflow_task_id: nil, reason: 'manual reset', request_id: nil, reset_reapply_type: Temporal::ResetReapplyType::SIGNAL)
      # Pick default strategy for backwards-compatibility
      strategy ||= :last_workflow_task unless workflow_task_id

      if strategy && workflow_task_id
        raise ArgumentError, 'Please specify either :strategy or :workflow_task_id'
      end

      workflow_task_id ||= find_workflow_task(namespace, workflow_id, run_id, strategy)&.id
      raise Error, 'Could not find an event to reset to' unless workflow_task_id

      if request_id.nil?
        # Generate a request ID if one is not provided.
        # This is consistent with the Go SDK:
        # https://github.com/temporalio/sdk-go/blob/e1d76b7c798828302980d483f0981128c97a20c2/internal/internal_workflow_client.go#L952-L972

        request_id = SecureRandom.uuid
      end

      response = connection.reset_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id,
        reason: reason,
        workflow_task_event_id: workflow_task_id,
        request_id: request_id,
        reset_reapply_type: reset_reapply_type
      )

      response.run_id
    end

    # Terminate a running workflow
    #
    # @param workflow_id [String]
    # @param namespace [String, nil] use a default namespace when `nil`
    # @param run_id [String, nil]
    # @param reason [String, nil] a termination reason to be recorded in workflow's history
    #   for reference
    # @param details [String, Array, nil] optional details to be stored in history
    def terminate_workflow(workflow_id, namespace: nil, run_id: nil, reason: nil, details: nil)
      namespace ||= Temporal.configuration.namespace

      connection.terminate_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id,
        reason: reason,
        details: details
      )
    end

    # Fetch workflow's execution info
    #
    # @param namespace [String]
    # @param workflow_id [String]
    # @param run_id [String]
    #
    # @return [Temporal::Workflow::ExecutionInfo] an object containing workflow status and other info
    def fetch_workflow_execution_info(namespace, workflow_id, run_id)
      response = connection.describe_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      Workflow::ExecutionInfo.generate_from(response.workflow_execution_info)
    end

    # Manually complete an activity
    #
    # @param async_token [String] an encoded Temporal::Activity::AsyncToken
    # @param result [String, Array, nil] activity's return value to be stored in history and
    #   passed back to a workflow
    def complete_activity(async_token, result = nil)
      details = Activity::AsyncToken.decode(async_token)

      connection.respond_activity_task_completed_by_id(
        namespace: details.namespace,
        activity_id: details.activity_id,
        workflow_id: details.workflow_id,
        run_id: details.run_id,
        result: result
      )
    end

    # Manually fail an activity
    #
    # @param async_token [String] an encoded Temporal::Activity::AsyncToken
    # @param exception [Exception] activity's failure exception to be stored in history and
    #   raised in a workflow
    def fail_activity(async_token, exception)
      details = Activity::AsyncToken.decode(async_token)

      connection.respond_activity_task_failed_by_id(
        namespace: details.namespace,
        activity_id: details.activity_id,
        workflow_id: details.workflow_id,
        run_id: details.run_id,
        exception: exception
      )
    end

    # Fetch workflow's execution history
    #
    # @param namespace [String]
    # @param workflow_id [String]
    # @param run_id [String]
    #
    # @return [Temporal::Workflow::History] workflow's execution history
    def get_workflow_history(namespace: nil, workflow_id:, run_id:)
      history_response = connection.get_workflow_execution_history(
        namespace: namespace || config.default_execution_options.namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      Workflow::History.new(history_response.history.events)
    end

    # Fetch workflow's execution history as JSON. This output can be used for replay testing.
    #
    # @param namespace [String]
    # @param workflow_id [String]
    # @param run_id [String] optional
    # @param pretty_print [Boolean] optional
    #
    # @return a JSON string representation of the history
    def get_workflow_history_json(namespace: nil, workflow_id:, run_id: nil, pretty_print: true)
      history_response = connection.get_workflow_execution_history(
        namespace: namespace || config.default_execution_options.namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )
      Temporal::Workflow::History::Serialization.to_json(history_response.history)
    end

    # Fetch workflow's execution history as protobuf binary. This output can be used for replay testing.
    #
    # @param namespace [String]
    # @param workflow_id [String]
    # @param run_id [String] optional
    #
    # @return a binary string representation of the history
    def get_workflow_history_protobuf(namespace: nil, workflow_id:, run_id: nil)
      history_response = connection.get_workflow_execution_history(
        namespace: namespace || config.default_execution_options.namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      # Protobuf for Ruby unfortunately does not support textproto. Plain binary provides
      # a less debuggable, but compact option.
      Temporal::Workflow::History::Serialization.to_protobuf(history_response.history)
    end

    def list_open_workflow_executions(namespace, from, to = Time.now, filter: {}, next_page_token: nil, max_page_size: nil)
      validate_filter(filter, :workflow, :workflow_id)

      Temporal::Workflow::Executions.new(connection: connection, status: :open, request_options: { namespace: namespace, from: from, to: to, next_page_token: next_page_token, max_page_size: max_page_size}.merge(filter))
    end

    def list_closed_workflow_executions(namespace, from, to = Time.now, filter: {}, next_page_token: nil, max_page_size: nil)
      validate_filter(filter, :status, :workflow, :workflow_id)

      Temporal::Workflow::Executions.new(connection: connection, status: :closed, request_options: { namespace: namespace, from: from, to: to, next_page_token: next_page_token, max_page_size: max_page_size}.merge(filter))
    end

    def query_workflow_executions(namespace, query, filter: {}, next_page_token: nil, max_page_size: nil)
      validate_filter(filter, :status, :workflow, :workflow_id)
      
      Temporal::Workflow::Executions.new(connection: connection, status: :all, request_options: { namespace: namespace, query: query, next_page_token: next_page_token, max_page_size: max_page_size }.merge(filter))
    end

    # Count the number of workflows matching the provided query
    # 
    # @param namespace [String]
    # @param query [String]
    #
    # @return [Integer] an integer count of workflows matching the query
    def count_workflow_executions(namespace, query: nil)
      response = connection.count_workflow_executions(namespace: namespace, query: query)
      response.count
    end

    # @param attributes [Hash[String, Symbol]] name to symbol for type, see INDEXED_VALUE_TYPE above
    # @param namespace String, required for SQL enhanced visibility, ignored for elastic search
    def add_custom_search_attributes(attributes, namespace: nil)
      connection.add_custom_search_attributes(attributes, namespace || config.default_execution_options.namespace)
    end

    # @param namespace String, required for SQL enhanced visibility, ignored for elastic search
    # @return Hash[String, Symbol] name to symbol for type, see INDEXED_VALUE_TYPE above
    def list_custom_search_attributes(namespace: nil)
      connection.list_custom_search_attributes(namespace || config.default_execution_options.namespace)
    end

    # @param attribute_names [Array[String]] Attributes to remove
    # @param namespace String, required for SQL enhanced visibility, ignored for elastic search
    def remove_custom_search_attributes(*attribute_names, namespace: nil)
      connection.remove_custom_search_attributes(attribute_names, namespace || config.default_execution_options.namespace)
    end

    # List all schedules in a namespace
    #
    # @param namespace [String] namespace to list schedules in
    # @param maximum_page_size [Integer] number of namespace results to return per page.
    # @param next_page_token [String] a optional pagination token returned by a previous list_namespaces call
    def list_schedules(namespace, maximum_page_size:, next_page_token: '')
      connection.list_schedules(namespace: namespace, maximum_page_size: maximum_page_size, next_page_token: next_page_token)
    end
 
    # Describe a schedule in a namespace
    #
    # @param namespace [String] namespace to list schedules in
    # @param schedule_id [String] schedule id
    def describe_schedule(namespace, schedule_id)
      connection.describe_schedule(namespace: namespace, schedule_id: schedule_id)
    end

    # Create a new schedule
    #
    #
    # @param namespace [String] namespace to create schedule in
    # @param schedule_id [String] schedule id
    # @param schedule [Temporal::Schedule::Schedule] schedule to create
    # @param trigger_immediately [Boolean] If set, trigger one action to run immediately
    # @param backfill [Temporal::Schedule::Backfill] If set, run through the backfill schedule and trigger actions.
    # @param memo [Hash] optional key-value memo map to attach to the schedule
    # @param search attributes [Hash] optional key-value search attributes to attach to the schedule
    def create_schedule(
      namespace,
      schedule_id,
      schedule,
      trigger_immediately: false,
      backfill: nil,
      memo: nil,
      search_attributes: nil
    )
      connection.create_schedule(
        namespace: namespace,
        schedule_id: schedule_id,
        schedule: schedule,
        trigger_immediately: trigger_immediately,
        backfill: backfill,
        memo: memo,
        search_attributes: search_attributes
      )
    end

    # Delete a schedule in a namespace
    #
    # @param namespace [String] namespace to list schedules in
    # @param schedule_id [String] schedule id
    def delete_schedule(namespace, schedule_id)
      connection.delete_schedule(namespace: namespace, schedule_id: schedule_id)
    end

    # Update a schedule in a namespace
    #
    # @param namespace [String] namespace to list schedules in
    # @param schedule_id [String] schedule id
    # @param schedule [Temporal::Schedule::Schedule] schedule to update. All fields in the schedule will be replaced completely by this updated schedule.
    # @param conflict_token [String] a token that was returned by a previous describe_schedule call. If provided and does not match the current schedule's token, the update will fail.
    def update_schedule(namespace, schedule_id, schedule, conflict_token: nil)
      connection.update_schedule(namespace: namespace, schedule_id: schedule_id, schedule: schedule, conflict_token: conflict_token)
    end

    # Trigger one action of a schedule to run immediately
    #
    # @param namespace [String] namespace
    # @param schedule_id [String] schedule id
    # @param overlap_policy [Symbol] Should be one of :skip, :buffer_one, :buffer_all, :cancel_other, :terminate_other, :allow_all
    def trigger_schedule(namespace, schedule_id, overlap_policy: nil)
      connection.trigger_schedule(namespace: namespace, schedule_id: schedule_id, overlap_policy: overlap_policy)
    end

    # Pause a schedule so actions will not run
    #
    # @param namespace [String] namespace
    # @param schedule_id [String] schedule id
    # @param note [String] an optional note to explain why the schedule was paused
    def pause_schedule(namespace, schedule_id, note: nil)
      connection.pause_schedule(namespace: namespace, schedule_id: schedule_id, should_pause: true, note: note)
    end

    # Unpause a schedule so actions will run
    #
    # @param namespace [String] namespace
    # @param schedule_id [String] schedule id
    # @param note [String] an optional note to explain why the schedule was unpaused
    def unpause_schedule(namespace, schedule_id, note: nil)
      connection.pause_schedule(namespace: namespace, schedule_id: schedule_id, should_pause: false, note: note)
    end

    def connection
      @connection ||= Temporal::Connection.generate(config.for_connection)
    end

    class ResultConverter
      extend Concerns::Payloads
    end
    private_constant :ResultConverter

    private

    attr_reader :config

    def compute_run_timeout(execution_options)
      execution_options.timeouts[:run] || execution_options.timeouts[:execution]
    end

    def find_workflow_task(namespace, workflow_id, run_id, strategy)
      history = get_workflow_history(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      # TODO: Move this into a separate class if it keeps growing
      case strategy
      when ResetStrategy::LAST_WORKFLOW_TASK
        events = %[WORKFLOW_TASK_COMPLETED WORKFLOW_TASK_TIMED_OUT WORKFLOW_TASK_FAILED].freeze
        history.events.select { |event| events.include?(event.type) }.last
      when ResetStrategy::FIRST_WORKFLOW_TASK
        events = %[WORKFLOW_TASK_COMPLETED WORKFLOW_TASK_TIMED_OUT WORKFLOW_TASK_FAILED].freeze
        history.events.select { |event| events.include?(event.type) }.first
      when ResetStrategy::LAST_FAILED_ACTIVITY
        events = %[ACTIVITY_TASK_FAILED ACTIVITY_TASK_TIMED_OUT].freeze
        failed_event = history.events.select { |event| events.include?(event.type) }.last
        return unless failed_event

        scheduled_event = history.find_event_by_id(failed_event.attributes.scheduled_event_id)
        history.find_event_by_id(scheduled_event.attributes.workflow_task_completed_event_id)
      else
        raise ArgumentError, 'Unsupported reset strategy'
      end
    end
    def validate_filter(filter, *allowed_filters)
      if (filter.keys - allowed_filters).length > 0
        raise ArgumentError, "Allowed filters are: #{allowed_filters}"
      end

      raise ArgumentError, 'Only one filter is allowed' if filter.size > 1
    end

  end
end
