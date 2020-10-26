require 'temporal/concerns/executable'

module Temporal
  class ExecutionOptions
    attr_reader :name, :namespace, :task_list, :retry_policy, :timeouts, :headers

    def initialize(object, options = {})
      @name = options[:name] || object.to_s
      @namespace = options[:namespace]
      @task_list = options[:task_list]
      @retry_policy = options[:retry_policy]
      @timeouts = options[:timeouts] || {}
      @headers = options[:headers] || {}

      if object.singleton_class.included_modules.include?(Concerns::Executable)
        @namespace ||= object.namespace
        @task_list ||= object.task_list
        @retry_policy ||= object.retry_policy
        @timeouts = object.timeouts.merge(@timeouts) if object.timeouts
        @headers = object.headers.merge(@headers) if object.headers
      end

      @namespace ||= Temporal.configuration.namespace
      @task_list ||= Temporal.configuration.task_list
      @timeouts = Temporal.configuration.timeouts.merge(@timeouts)
      @headers = Temporal.configuration.headers.merge(@headers)

      freeze
    end
  end
end
