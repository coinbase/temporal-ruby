require 'temporal/client'
require 'temporal/workflow/poller'
require 'temporal/activity/poller'
require 'temporal/execution_options'
require 'temporal/executable_lookup'
require 'temporal/middleware/entry'

module Temporal
  class Worker
    DEFAULT_SHUTDOWN_GRACE_PERIOD = 25 # seconds

    # activity_thread_pool_size: number of threads that the poller can use to run activities.
    #   can be set to 1 if you want no paralellism in your activities, at the cost of throughput.
    def initialize(activity_thread_pool_size: Temporal::Activity::Poller::DEFAULT_OPTIONS[:thread_pool_size], shutdown_grace_period: DEFAULT_SHUTDOWN_GRACE_PERIOD)
      @workflows = Hash.new { |hash, key| hash[key] = ExecutableLookup.new }
      @activities = Hash.new { |hash, key| hash[key] = ExecutableLookup.new }
      @pollers = []
      @workflow_task_middleware = []
      @activity_middleware = []
      @shutting_down = false
      @activity_poller_options = {
        thread_pool_size: activity_thread_pool_size,
      }
      @shutdown_grace_period = shutdown_grace_period
    end

    def register_workflow(workflow_class, options = {})
      execution_options = ExecutionOptions.new(workflow_class, options)
      key = [execution_options.namespace, execution_options.task_queue]

      @workflows[key].add(execution_options.name, workflow_class)
    end

    def register_activity(activity_class, options = {})
      execution_options = ExecutionOptions.new(activity_class, options)
      key = [execution_options.namespace, execution_options.task_queue]

      @activities[key].add(execution_options.name, activity_class)
    end

    def add_workflow_task_middleware(middleware_class, *args)
      @workflow_task_middleware << Middleware::Entry.new(middleware_class, args)
    end

    def add_activity_middleware(middleware_class, *args)
      @activity_middleware << Middleware::Entry.new(middleware_class, args)
    end

    def start
      workflows.each_pair do |(namespace, task_queue), lookup|
        pollers << workflow_poller_for(namespace, task_queue, lookup)
      end

      activities.each_pair do |(namespace, task_queue), lookup|
        pollers << activity_poller_for(namespace, task_queue, lookup)
      end

      trap_signals

      pollers.each(&:start)

      # keep the main thread alive
      sleep 1 while !shutting_down?
    end

    def stop
      @shutting_down = true

      Thread.new do
        pollers.each(&:stop_polling)
        # allow workers to drain in-transit tasks.
        # https://github.com/temporalio/temporal/issues/1058
        sleep @shutdown_grace_period
        pollers.each(&:cancel_pending_requests)
        pollers.each(&:wait)
      end.join
    end

    private

    attr_reader :activity_poller_options, :activities, :workflows, :pollers,
                :workflow_task_middleware, :activity_middleware

    def shutting_down?
      @shutting_down
    end

    def workflow_poller_for(namespace, task_queue, lookup)
      Workflow::Poller.new(namespace, task_queue, lookup.freeze, workflow_task_middleware)
    end

    def activity_poller_for(namespace, task_queue, lookup)
      Activity::Poller.new(namespace, task_queue, lookup.freeze, activity_middleware, activity_poller_options)
    end

    def trap_signals
      %w[TERM INT].each do |signal|
        Signal.trap(signal) { stop }
      end
    end
  end
end
