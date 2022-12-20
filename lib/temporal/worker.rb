require 'temporal/workflow/poller'
require 'temporal/activity/poller'
require 'temporal/execution_options'
require 'temporal/executable_lookup'
require 'temporal/middleware/entry'

module Temporal
  class Worker
    # activity_thread_pool_size: number of threads that the poller can use to run activities.
    #   can be set to 1 if you want no paralellism in your activities, at the cost of throughput.

    # binary_checksum: The binary checksum identifies the version of workflow worker code. It is set on each completed or failed workflow
    #   task. It is present in API responses that return workflow execution info, and is shown in temporal-web and tctl.
    #   It is traditionally a checksum of the application binary. However, Temporal server treats this as an opaque
    #   identifier and it does not have to be a "checksum". Typical values for a Ruby application might include the hash
    #   of the latest git commit or a semantic version number.
    #
    #   It can be used to reset workflow history to before a "bad binary" was deployed. Bad checksum values can also
    #   be marked at the namespace level. This will cause Temporal server to reject any polling for workflow tasks
    #   from workers with these bad versions.
    #
    #   See https://docs.temporal.io/docs/tctl/how-to-use-tctl/#recovery-from-bad-deployment----auto-reset-workflow
    def initialize(
      config = Temporal.configuration,
      activity_thread_pool_size: Temporal::Activity::Poller::DEFAULT_OPTIONS[:thread_pool_size],
      workflow_thread_pool_size: Temporal::Workflow::Poller::DEFAULT_OPTIONS[:thread_pool_size],
      binary_checksum: Temporal::Workflow::Poller::DEFAULT_OPTIONS[:binary_checksum]
    )
      @config = config
      @workflows = Hash.new { |hash, key| hash[key] = ExecutableLookup.new }
      @activities = Hash.new { |hash, key| hash[key] = ExecutableLookup.new }
      @pollers = []
      @workflow_task_middleware = []
      @activity_middleware = []
      @shutting_down = false
      @activity_poller_options = {
        thread_pool_size: activity_thread_pool_size,
      }
      @workflow_poller_options = {
        thread_pool_size: workflow_thread_pool_size,
        binary_checksum: binary_checksum
      }
    end

    def register_workflow(workflow_class, options = {})
      execution_options = ExecutionOptions.new(workflow_class, options, config.default_execution_options)
      key = [execution_options.namespace, execution_options.task_queue]

      @workflows[key].add(execution_options.name, workflow_class)
    end

    def register_activity(activity_class, options = {})
      if activity_class.dynamic?
        raise ArgumentError,
              "Activity #{activity_class} is marked as dynamic and must be registered using register_dynamic_activity."
      end

      register_any_activity(activity_class, options)
    end

    def register_dynamic_activity(activity_class, options = {})
      unless activity_class.dynamic?
        raise ArgumentError,
              "Activity #{activity_class} is not marked as dynamic and cannot be registered using register_dynamic_activity."
      end

      register_any_activity(activity_class, options)
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
        sleep 1
        pollers.each(&:cancel_pending_requests)
        pollers.each(&:wait)
      end.join
    end

    private

    attr_reader :config, :activity_poller_options, :workflow_poller_options,
                :activities, :workflows, :pollers,
                :workflow_task_middleware, :activity_middleware

    def shutting_down?
      @shutting_down
    end

    def workflow_poller_for(namespace, task_queue, lookup)
      Workflow::Poller.new(namespace, task_queue, lookup.freeze, config, workflow_task_middleware, workflow_poller_options)
    end

    def activity_poller_for(namespace, task_queue, lookup)
      Activity::Poller.new(namespace, task_queue, lookup.freeze, config, activity_middleware, activity_poller_options)
    end

    def trap_signals
      %w[TERM INT].each do |signal|
        Signal.trap(signal) { stop }
      end
    end

    def register_any_activity(activity_class, options)
      execution_options = ExecutionOptions.new(activity_class, options, config.default_execution_options)
      key = [execution_options.namespace, execution_options.task_queue]

      @activities[key].add(execution_options.name, activity_class)
    end
  end
end
