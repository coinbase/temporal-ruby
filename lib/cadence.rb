require 'securerandom'
require 'cadence/configuration'
require 'cadence/execution_options'
require 'cadence/client'
require 'cadence/activity'
require 'cadence/activity/async_token'
require 'cadence/workflow'
require 'cadence/workflow/history'
require 'cadence/metrics'

module Cadence
  class << self
    def start_workflow(workflow, *input, **args)
      options = args.delete(:options) || {}
      input << args unless args.empty?

      execution_options = ExecutionOptions.new(workflow, options)
      workflow_id = options[:workflow_id] || SecureRandom.uuid

      response = client.start_workflow_execution(
        domain: execution_options.domain,
        workflow_id: workflow_id,
        workflow_name: execution_options.name,
        task_list: execution_options.task_list,
        input: input,
        execution_timeout: execution_options.timeouts[:execution],
        task_timeout: execution_options.timeouts[:task],
        workflow_id_reuse_policy: options[:workflow_id_reuse_policy],
        headers: execution_options.headers
      )

      response.runId
    end

    def register_domain(name, description = nil)
      client.register_domain(name: name, description: description)
    end

    def signal_workflow(workflow, signal, workflow_id, run_id, input = nil)
      client.signal_workflow_execution(
        domain: workflow.domain, # TODO: allow passing domain instead
        workflow_id: workflow_id,
        run_id: run_id,
        signal: signal,
        input: input
      )
    end

    def reset_workflow(domain, workflow_id, run_id, reason = 'manual reset')
      history_response = client.get_workflow_execution_history(
        domain: domain,
        workflow_id: workflow_id,
        run_id: run_id
      )
      history = Workflow::History.new(history_response.history.events)
      decision_task_event = history.last_completed_decision_task

      raise Error, 'Could not find a completed decision task event' unless decision_task_event

      response = client.reset_workflow_execution(
        domain: domain,
        workflow_id: workflow_id,
        run_id: run_id,
        reason: reason,
        decision_task_event_id: decision_task_event.id
      )

      response.runId
    end

    def complete_activity(async_token, result = nil)
      details = Activity::AsyncToken.decode(async_token)

      client.respond_activity_task_completed_by_id(
        domain: details.domain,
        activity_id: details.activity_id,
        workflow_id: details.workflow_id,
        run_id: details.run_id,
        result: result
      )
    end

    def fail_activity(async_token, error)
      details = Activity::AsyncToken.decode(async_token)

      client.respond_activity_task_failed_by_id(
        domain: details.domain,
        activity_id: details.activity_id,
        workflow_id: details.workflow_id,
        run_id: details.run_id,
        reason: error.class.name,
        details: error.message
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

    def client
      @client ||= Cadence::Client.generate
    end
  end
end
