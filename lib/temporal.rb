# Protoc wants all of its generated files on the LOAD_PATH
$LOAD_PATH << File.expand_path('./gen', __dir__)

require 'securerandom'
require 'temporal/configuration'
require 'temporal/execution_options'
require 'temporal/client'
require 'temporal/activity'
require 'temporal/activity/async_token'
require 'temporal/workflow'
require 'temporal/workflow/history'
require 'temporal/workflow/execution_info'
require 'temporal/metrics'
require 'temporal/json'
require 'temporal/errors'
require 'temporal/workflow/errors'

module Temporal
  class << self
    def start_workflow(workflow, *input, **args)
      options = args.delete(:options) || {}
      input << args unless args.empty?

      execution_options = ExecutionOptions.new(workflow, options)
      workflow_id = options[:workflow_id] || SecureRandom.uuid

      response = client.start_workflow_execution(
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

      execution_options = ExecutionOptions.new(workflow, options)
      workflow_id = options[:workflow_id] || SecureRandom.uuid

      response = client.start_workflow_execution(
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
      client.register_namespace(name: name, description: description)
    end

    def signal_workflow(workflow, signal, workflow_id, run_id, input = nil)
      execution_options = ExecutionOptions.new(workflow)

      client.signal_workflow_execution(
        namespace: execution_options.namespace, # TODO: allow passing namespace instead
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
    # timeout_s: seconds to wait for the result.  This cannot be longer than 30 seconds because
    # that is the maximum the server supports.
    # namespace: if nil, choose the one declared on the Workflow, or the global default
    def await_workflow_result(workflow, workflow_id:, run_id: nil, timeout_s: nil, namespace: nil)
      options = namespace ? {namespace: namespace} : {}
      execution_options = ExecutionOptions.new(workflow, options)
      max_timeout_s = 30 # Hardcoded in the temporal server.
      current_run_id = run_id
      loop do
        history_response = nil
        begin
          history_response = client.get_workflow_execution_history(
            namespace: execution_options.namespace,
            workflow_id: workflow_id,
            run_id: current_run_id,
            wait_for_new_event: true,
            event_type: :close,
            timeout_s: timeout_s || max_timeout_s,
          )
        rescue GRPC::DeadlineExceeded => e
          message = if timeout_s 
            "Timed out after your specified limit of timeout_s: #{timeout_s} seconds"
          else
            "Timed out after #{max_timeout_s} seconds, which is the maximum supported amount."
          end
          raise TimeoutError.new(message)
        end
        history = Workflow::History.new(history_response.history.events)
        closed_event = history.events.first
        case closed_event.type
        when 'WORKFLOW_EXECUTION_COMPLETED'
          payloads = closed_event.attributes.result
          return from_result_payloads(payloads)
        when 'WORKFLOW_EXECUTION_TIMED_OUT'
          raise Temporal::WorkflowTimedOut
        when 'WORKFLOW_EXECUTION_TERMINATED'
          raise Temporal::WorkflowTerminated
        when 'WORKFLOW_EXECUTION_CANCELED'
          raise Temporal::WorkflowCanceled
        when 'WORKFLOW_EXECUTION_FAILED'
          raise Temporal::Workflow::Errors.new.error_from(closed_event.attributes.failure)
        when 'WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
          new_run_id = closed_event.attributes.new_execution_run_id
          if run_id
            # If they specified a run ID, we should throw to let them know they're not getting the result
            # they wanted.  They can re-call on the new run ID if they want.
            raise Temporal::WorkflowRunContinuedAsNew.new(new_run_id: new_run_id)
          else
            current_run_id = new_run_id
            # await the next run until the workflow is complete.
          end
        else
          raise NotImplementedError, "Unexpected event type #{closed_event.type}."
        end
      end
    end

    def reset_workflow(namespace, workflow_id, run_id, workflow_task_id: nil, reason: 'manual reset')
      workflow_task_id ||= get_last_completed_workflow_task_id(namespace, workflow_id, run_id)
      raise Error, 'Could not find a completed workflow task event' unless workflow_task_id

      response = client.reset_workflow_execution(
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

      client.terminate_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id,
        reason: reason,
        details: details
      )
    end

    def fetch_workflow_execution_info(namespace, workflow_id, run_id)
      response = client.describe_workflow_execution(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )

      Workflow::ExecutionInfo.generate_from(response.workflow_execution_info)
    end

    def complete_activity(async_token, result = nil)
      details = Activity::AsyncToken.decode(async_token)

      client.respond_activity_task_completed_by_id(
        namespace: details.namespace,
        activity_id: details.activity_id,
        workflow_id: details.workflow_id,
        run_id: details.run_id,
        result: result
      )
    end

    def fail_activity(async_token, exception)
      details = Activity::AsyncToken.decode(async_token)

      client.respond_activity_task_failed_by_id(
        namespace: details.namespace,
        activity_id: details.activity_id,
        workflow_id: details.workflow_id,
        run_id: details.run_id,
        exception: exception
      )
    end

    def configure(&block)
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def logger
      configuration.logger
    end

    def metrics
      @metrics ||= Metrics.new(configuration.metrics_adapter)
    end

    private

    include Concerns::Payloads

    def client
      @client ||= Temporal::Client.generate
    end

    def get_last_completed_workflow_task_id(namespace, workflow_id, run_id)
      history_response = client.get_workflow_execution_history(
        namespace: namespace,
        workflow_id: workflow_id,
        run_id: run_id
      )
      history = Workflow::History.new(history_response.history.events)
      workflow_task_event = history.get_last_completed_workflow_task
      workflow_task_event&.id
    end
  end
end
