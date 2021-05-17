require 'temporal/concerns/executable'

module Temporal
  class ExecutionOptions
    attr_reader :name, :namespace, :task_queue, :retry_policy, :timeouts, :headers

    def initialize(object, options = {})
      @name = options[:name] || object.to_s
      @namespace = options[:namespace]
      @task_queue = options[:task_queue] || options[:task_list]
      @retry_policy = options[:retry_policy]
      @timeouts = options[:timeouts] || {}
      @headers = options[:headers] || {}

      if has_executable_concern?(object)
        @namespace ||= object.namespace
        @task_queue ||= object.task_queue
        @retry_policy ||= object.retry_policy
        @timeouts = object.timeouts.merge(@timeouts) if object.timeouts
        @headers = object.headers.merge(@headers) if object.headers
      end

      @namespace ||= Temporal.configuration.namespace
      @task_queue ||= Temporal.configuration.task_queue
      @timeouts = Temporal.configuration.timeouts.merge(@timeouts)
      @headers = Temporal.configuration.headers.merge(@headers)

      freeze
    end

    def task_list
      @task_queue
    end

    private

    def has_executable_concern?(object)
      object.singleton_class.included_modules.include?(Concerns::Executable)
    rescue TypeError
      false
    end
  end
end
