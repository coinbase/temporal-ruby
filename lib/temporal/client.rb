require 'temporal/execution_options'
require 'temporal/connection'
require 'temporal/activity'
require 'temporal/activity/async_token'
require 'temporal/workflow'
require 'temporal/workflow/history'
require 'temporal/workflow/execution_info'
require 'temporal/reset_strategy'

module Temporal
  class Client
    def initialize(config)
      @config = config
    end

    def start_workflow(workflow, *input, **args)
      options = args.delete(:options) || {}
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
        # If unspecified, individual runs should have the full time for the execution (which includes retries).
        run_timeout: execution_options.timeouts[:run] || execution_options.timeouts[:execution],
        task_timeout: execution_options.timeouts[:task],
        workflow_id_reuse_policy: options[:workflow_id_reuse_policy],
        headers: execution_options.headers
      )

      response.run_id
    end

    def schedule_workflow(workflow, cron_schedule, *input, **args)
      options = args.delete(:options) || {}
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
        run_timeout: execution_options.timeouts[:run] || execution_options.timeouts[:execution],
        task_timeout: execution_options.timeouts[:task],
        workflow_id_reuse_policy: options[:workflow_id_reuse_policy],
        headers: execution_options.headers,
        cron_schedule: cron_schedule
      )

      response.run_id
    end

    def register_namespace(name, description = nil)
      connection.register_namespace(name: name, description: description)
    end

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

    # Long polls for a workflow to be completed and returns whatever the execute function
    # returned.  This function times out after 30 seconds and throws Temporal::TimeoutError,
    # not to be confused with Temporal::WorkflowTimedOut which reports that the workflow
    # itself timed out.
    # run_id of nil: await the entire workflow completion.  This can span multiple runs
    # in the case where the workflow uses continue-as-new.
    # timeout: seconds to wait for the result.  This cannot be longer than 30 seconds because
    # that is the maximum the server supports.
    # namespace: if nil, choose the one declared on the Workflow, or the global default
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

    def fetch_workflow_execution_info(namespace, workflow_id, run_id)
      response = connection.describe_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      Workflow::ExecutionInfo.generate_from(response.workflow_execution_info)
    end

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

    def get_workflow_history(namespace:, workflow_id:, run_id:)
      history_response = connection.get_workflow_execution_history(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      Workflow::History.new(history_response.history.events)
    end

    class ResultConverter
      extend Concerns::Payloads
    end
    private_constant :ResultConverter

    private

    attr_reader :config

    def connection
      @connection ||= Temporal::Connection.generate(config.for_connection)
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
  end
end
