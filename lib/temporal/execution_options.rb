require 'temporal/concerns/executable'
require 'temporal/retry_policy'

module Temporal
  class ExecutionOptions
    attr_reader :name, :namespace, :task_queue, :retry_policy, :timeouts, :headers, :memo, :search_attributes, :workflow_id_reuse_policy

    def initialize(object, options, defaults = nil)
      # Options are treated as overrides and take precedence
      @name = options[:name] || object.to_s
      @namespace = options[:namespace]
      @task_queue = options[:task_queue] || options[:task_list]
      @retry_policy = options[:retry_policy] || {}
      @timeouts = options[:timeouts] || {}
      @headers = options[:headers] || {}
      @memo = options[:memo] || {}
      @search_attributes = options[:search_attributes] || {}
      @workflow_id_reuse_policy = options[:workflow_id_reuse_policy]

      # For Temporal::Workflow and Temporal::Activity use defined values as the next option
      if has_executable_concern?(object)
        @namespace ||= object.namespace
        @task_queue ||= object.task_queue
        @retry_policy = object.retry_policy.merge(@retry_policy) if object.retry_policy
        @timeouts = object.timeouts.merge(@timeouts) if object.timeouts
        @headers = object.headers.merge(@headers) if object.headers
        @workflow_id_reuse_policy ||= object.workflow_id_reuse_policy
      end

      # Lastly consider defaults if they are given
      if defaults
        @namespace ||= defaults.namespace
        @task_queue ||= defaults.task_queue
        @timeouts = defaults.timeouts.merge(@timeouts)
        @headers = defaults.headers.merge(@headers)
        @search_attributes = defaults.search_attributes.merge(@search_attributes)
        @workflow_id_reuse_policy ||= defaults.workflow_id_reuse_policy
      end

      if @retry_policy.empty?
        @retry_policy = nil
      else
        @retry_policy = Temporal::RetryPolicy.new(@retry_policy)
        @retry_policy.validate!
      end

      freeze
    end

    def task_list
      @task_queue
    end

    private

    def has_executable_concern?(object)
      # NOTE: When object is a String .dup is needed since Object#singleton_class mutates
      #       it and screws up C extension class detection (used by Protobufs)
      object.dup.singleton_class.included_modules.include?(Concerns::Executable)
    rescue TypeError
      false
    end
  end
end
