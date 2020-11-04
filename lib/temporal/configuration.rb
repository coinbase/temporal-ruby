require 'logger'
require 'temporal/metrics_adapters/null'

module Temporal
  class Configuration
    attr_reader :timeouts
    attr_accessor :client_type, :host, :port, :logger, :metrics_adapter, :namespace, :task_queue, :headers

    DEFAULT_TIMEOUTS = {
      execution: 60,          # End-to-end workflow time
      task: 10,               # Workflow task processing time
      schedule_to_close: nil, # End-to-end activity time (default: schedule_to_start + start_to_close)
      schedule_to_start: 10,  # Queue time for an activity
      start_to_close: 30,     # Time spent processing an activity
      heartbeat: nil          # Max time between heartbeats (off by default)
    }.freeze

    DEFAULT_HEADERS = {}.freeze
    DEFAULT_NAMESPACE = 'default-namespace'.freeze
    DEFAULT_TASK_QUEUE = 'default-task-queue'.freeze

    def initialize
      @client_type = :grpc
      @logger = Logger.new(STDOUT, progname: 'temporal_client')
      @metrics_adapter = MetricsAdapters::Null.new
      @timeouts = DEFAULT_TIMEOUTS
      @namespace = DEFAULT_NAMESPACE
      @task_queue = DEFAULT_TASK_QUEUE
      @headers = DEFAULT_HEADERS
    end

    def task_list
      @task_queue
    end

    def task_list=(name)
      self.task_queue = name
    end

    def timeouts=(new_timeouts)
      @timeouts = DEFAULT_TIMEOUTS.merge(new_timeouts)
    end
  end
end
