require 'temporal/execution_options'
require 'temporal/connection'
require 'temporal/activity'
require 'temporal/activity/async_token'
require 'temporal/workflow'
require 'temporal/workflow/context_helpers'
require 'temporal/workflow/history'
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
          workflow_id_reuse_policy: options[:workflow_id_reuse_policy] || execution_options.workflow_id_reuse_policy,
          headers: execution_options.headers,
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
          workflow_id_reuse_policy: options[:workflow_id_reuse_policy] || execution_options.workflow_id_reuse_policy,
          headers: execution_options.headers,
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
        workflow_id_reuse_policy: options[:workflow_id_reuse_policy] || execution_options.workflow_id_reuse_policy,
        headers: execution_options.headers,
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
    # @return [Hash] info deserialized from Temporal::Api::WorkflowService::V1::DescribeNamespaceResponse
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
    #   https://docs.temporal.io/docs/system-tools/tctl/#restart-reset-workflow
    #
    # @param namespace [String]
    # @param workflow_id [String]
    # @param run_id [String]
    # @param strategy [Symbol, nil] one of the Temporal::ResetStrategy values or `nil` when
    #   passing a workflow_task_id
    # @param workflow_task_id [Integer, nil] A specific event ID to reset to. The event has to
    #   be of a type WorkflowTaskCompleted, WorkflowTaskFailed or WorkflowTaskTimedOut
    # @param reason [String] a reset reason to be recorded in workflow's history for reference
    #
    # @return [String] run_id of the new workflow execution
    def reset_workflow(namespace, workflow_id, run_id, strategy: nil, workflow_task_id: nil, reason: 'manual reset')
      # Pick default strategy for backwards-compatibility
      strategy ||= :last_workflow_task unless workflow_task_id

      if strategy && workflow_task_id
        raise ArgumentError, 'Please specify either :strategy or :workflow_task_id'
      end

      workflow_task_id ||= find_workflow_task(namespace, workflow_id, run_id, strategy)&.id
      raise Error, 'Could not find an event to reset to' unless workflow_task_id

      response = connection.reset_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id,
        reason: reason,
        workflow_task_event_id: workflow_task_id
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
    def get_workflow_history(namespace:, workflow_id:, run_id:)
      history_response = connection.get_workflow_execution_history(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      Workflow::History.new(history_response.history.events)
    end

    def list_open_workflow_executions(namespace, from, to = Time.now, filter: {}, next_page_token: nil, max_page_size: nil)
      validate_filter(filter, :workflow, :workflow_id)

      Temporal::Workflow::Executions.new(connection: connection, status: :open, request_options: { namespace: namespace, from: from, to: to, next_page_token: next_page_token, max_page_size: max_page_size}.merge(filter))
    end

    def list_closed_workflow_executions(namespace, from, to = Time.now, filter: {}, next_page_token: nil, max_page_size: nil)
      validate_filter(filter, :status, :workflow, :workflow_id)

      Temporal::Workflow::Executions.new(connection: connection, status: :closed, request_options: { namespace: namespace, from: from, to: to, next_page_token: next_page_token, max_page_size: max_page_size}.merge(filter))
    end

    def query_workflow_executions(namespace, query, next_page_token: nil, max_page_size: nil)
      Temporal::Workflow::Executions.new(connection: connection, status: :all, request_options: { namespace: namespace, query: query, next_page_token: next_page_token, max_page_size: max_page_size }.merge(filter))
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
