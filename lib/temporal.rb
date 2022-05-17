# Protoc wants all of its generated files on the LOAD_PATH
$LOAD_PATH << File.expand_path('./gen', __dir__)

require 'securerandom'
require 'forwardable'
require 'temporal/configuration'
require 'temporal/client'
require 'temporal/metrics'
require 'temporal/json'
require 'temporal/errors'
require 'temporal/workflow/errors'

module Temporal
  extend SingleForwardable

  def_delegators :default_client, #target
                 :start_workflow,
                 :schedule_workflow,
                 :register_namespace,
                 :describe_namespace,
                 :list_namespaces,
                 :signal_workflow,
                 :query_workflow,
                 :await_workflow_result,
                 :reset_workflow,
                 :terminate_workflow,
                 :fetch_workflow_execution_info,
                 :complete_activity,
                 :fail_activity,
                 :get_cron_schedule,
                 :list_open_workflow_executions,
                 :list_closed_workflow_executions,
                 :query_workflow_executions

  class << self
    def configure(&block)
      yield config
    end

    def configuration
      config
    end

    def logger
      config.logger
    end

    def metrics
      @metrics ||= Metrics.new(config.metrics_adapter)
    end

    class ResultConverter
      extend Concerns::Payloads
    end
    private_constant :ResultConverter

    private

    def default_client
      @default_client ||= Client.new(config)
    end

    def config
      @config ||= Configuration.new
    end

  end
end
