require 'cadence/concerns/executable'

module Cadence
  class ExecutionOptions
    attr_reader :name, :domain, :task_list, :retry_policy, :timeouts

    def initialize(object, options = {})
      @name = options[:name] || object.to_s
      @domain = options[:domain]
      @task_list = options[:task_list]
      @retry_policy = options[:retry_policy]
      @timeouts = options[:timeouts] || {}

      if object.singleton_class.included_modules.include?(Concerns::Executable)
        @domain ||= object.domain
        @task_list ||= object.task_list
        @retry_policy ||= object.retry_policy
        @timeouts = object.timeouts.merge(@timeouts) if object.timeouts
      end

      @domain ||= Cadence.configuration.domain
      @task_list ||= Cadence.configuration.task_list
      @timeouts = Cadence.configuration.timeouts.merge(@timeouts)

      freeze
    end
  end
end
