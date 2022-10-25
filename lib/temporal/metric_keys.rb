module Temporal
  class MetricKeys
    ACTIVITY_POLLER_TIME_SINCE_LAST_POLL = 'activity_poller.time_since_last_poll'.freeze
    ACTIVITY_POLLER_POLL_COMPLETED = 'activity_poller.poll_completed'.freeze
    ACTIVITY_TASK_QUEUE_TIME = 'activity_task.queue_time'.freeze
    ACTIVITY_TASK_LATENCY = 'activity_task.latency'.freeze

    WORKFLOW_POLLER_TIME_SINCE_LAST_POLL = 'workflow_poller.time_since_last_poll'.freeze
    WORKFLOW_POLLER_POLL_COMPLETED = 'workflow_poller.poll_completed'.freeze
    WORKFLOW_TASK_QUEUE_TIME = 'workflow_task.queue_time'.freeze
    WORKFLOW_TASK_LATENCY = 'workflow_task.latency'.freeze
    WORKFLOW_TASK_EXECUTION_FAILED = 'workflow_task.execution_failed'.freeze

    THREAD_POOL_AVAILABLE_THREADS = 'thread_pool.available_threads'.freeze
  end
end
