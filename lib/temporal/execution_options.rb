require 'temporal/concerns/executable'

module Temporal
  class ExecutionOptions
    attr_reader :name, :domain, :task_list, :retry_policy, :timeouts, :headers

    def initialize(object, options = {})
      @name = options[:name] || object.to_s
      @domain = options[:domain]
      @task_list = options[:task_list]
      @retry_policy = options[:retry_policy]
      @timeouts = options[:timeouts] || {}
      @headers = options[:headers] || {}

      if object.singleton_class.included_modules.include?(Concerns::Executable)
        @domain ||= object.domain
        @task_list ||= object.task_list
        @retry_policy ||= object.retry_policy
        @timeouts = object.timeouts.merge(@timeouts) if object.timeouts
        @headers = object.headers.merge(@headers) if object.headers
      end

      @domain ||= Temporal.configuration.domain
      @task_list ||= Temporal.configuration.task_list
      @timeouts = Temporal.configuration.timeouts.merge(@timeouts)
      @headers = Temporal.configuration.headers.merge(@headers)

      freeze
    end
  end
end
