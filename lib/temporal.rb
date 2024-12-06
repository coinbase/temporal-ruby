# Protoc wants all of its generated files on the LOAD_PATH
$LOAD_PATH << File.expand_path('./gen', __dir__)

require 'securerandom'
require 'forwardable'
require 'temporal/configuration'
require 'temporal/client'
require 'temporal/metrics'
require 'temporal/json'
require 'temporal/errors'
require 'temporal/schedule'
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
                 :get_workflow_history,
                 :list_open_workflow_executions,
                 :list_closed_workflow_executions,
                 :query_workflow_executions,
                 :count_workflow_executions,
                 :add_custom_search_attributes,
                 :list_custom_search_attributes,
                 :remove_custom_search_attributes,
                 :connection,
                 :list_schedules,
                 :describe_schedule,
                 :create_schedule,
                 :delete_schedule,
                 :update_schedule,
                 :trigger_schedule,
                 :pause_schedule,
                 :unpause_schedule,
                 :get_workflow_history,
                 :get_workflow_history_json,
                 :get_workflow_history_protobuf

  class << self
    def configure(&block)
      yield config
      # Reset the singleton client after configuration was altered to ensure
      # it is initialized with the latest attributes
      @default_client = nil
    end

    def configuration
      warn '[DEPRECATION] This method is now deprecated without a substitution'
      config
    end

    def logger
      config.logger
    end

    def metrics
      @metrics ||= Metrics.new(config.metrics_adapter)
    end

    private

    def default_client
      @default_client ||= Client.new(config)
    end

    def config
      @config ||= Configuration.new
    end

  end
end
