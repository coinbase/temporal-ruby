require 'securerandom'
require 'cadence/configuration'
require 'cadence/execution_options'
require 'cadence/client'
require 'cadence/activity'
require 'cadence/workflow'

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
        workflow_id_reuse_policy: options[:workflow_id_reuse_policy]
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

    def configure(&block)
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def logger
      configuration.logger
    end

    private

    def client
      @client ||= Cadence::Client.generate
    end
  end
end
