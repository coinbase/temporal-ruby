require 'temporal/client'
require 'temporal/workflow/poller'
require 'temporal/activity/poller'
require 'temporal/execution_options'
require 'temporal/executable_lookup'
require 'temporal/middleware/entry'

module Temporal
  class Worker
    def initialize
      @workflows = Hash.new { |hash, key| hash[key] = ExecutableLookup.new }
      @activities = Hash.new { |hash, key| hash[key] = ExecutableLookup.new }
      @pollers = []
      @decision_middleware = []
      @activity_middleware = []
      @shutting_down = false
    end

    def register_workflow(workflow_class, options = {})
      execution_options = ExecutionOptions.new(workflow_class, options)
      key = [execution_options.namespace, execution_options.task_list]

      @workflows[key].add(execution_options.name, workflow_class)
    end

    def register_activity(activity_class, options = {})
      execution_options = ExecutionOptions.new(activity_class, options)
      key = [execution_options.namespace, execution_options.task_list]

      @activities[key].add(execution_options.name, activity_class)
    end

    def add_decision_middleware(middleware_class, *args)
      @decision_middleware << Middleware::Entry.new(middleware_class, args)
    end

    def add_activity_middleware(middleware_class, *args)
      @activity_middleware << Middleware::Entry.new(middleware_class, args)
    end

    def start
      workflows.each_pair do |(namespace, task_list), lookup|
        pollers << workflow_poller_for(namespace, task_list, lookup)
      end

      activities.each_pair do |(namespace, task_list), lookup|
        pollers << activity_poller_for(namespace, task_list, lookup)
      end

      trap_signals

      pollers.each(&:start)

      # wait until instructed to shut down
      while !shutting_down? do
        sleep 1
      end
    end

    def stop
      @shutting_down = true
      pollers.each(&:stop)
      pollers.each(&:wait)
    end

    private

    attr_reader :activities, :workflows, :pollers, :decision_middleware, :activity_middleware

    def shutting_down?
      @shutting_down
    end

    def workflow_poller_for(namespace, task_list, lookup)
      Workflow::Poller.new(namespace, task_list, lookup.freeze, decision_middleware)
    end

    def activity_poller_for(namespace, task_list, lookup)
      Activity::Poller.new(namespace, task_list, lookup.freeze, activity_middleware)
    end

    def trap_signals
      %w[TERM INT].each do |signal|
        Signal.trap(signal) { stop }
      end
    end
  end
end
