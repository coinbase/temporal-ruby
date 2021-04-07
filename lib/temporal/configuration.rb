require 'logger'
require 'temporal/metrics_adapters/null'
require 'temporal/client/converter/nil'
require 'temporal/client/converter/bytes'
require 'temporal/client/converter/json'
require 'temporal/client/converter/legacy'
require 'temporal/client/converter/composite'

module Temporal
  class Configuration
    attr_reader :timeouts, :error_handlers
    attr_writer :converter
    attr_accessor :client_type, :host, :port, :logger, :metrics_adapter, :namespace, :task_queue, :headers

    # We want an infinite execution timeout for cron schedules and other perpetual workflows.
    # We choose an 10-year execution timeout because that's the maximum the cassandra DB supports,
    # matching the go SDK, see https://github.com/temporalio/sdk-go/blob/d96130dad3d2bc189bc7626543bd5911cc07ff6d/internal/internal_workflow_testsuite.go#L68
    DEFAULT_TIMEOUTS = {
      execution: 86_400 * 365 * 10, # End-to-end workflow time, including all recurrences if it's scheduled.
      task: 10,               # Workflow task processing time
      schedule_to_close: nil, # End-to-end activity time (default: schedule_to_start + start_to_close)
      schedule_to_start: 10,  # Queue time for an activity
      start_to_close: 30,     # Time spent processing an activity
      heartbeat: nil          # Max time between heartbeats (off by default)
    }.freeze

    DEFAULT_HEADERS = {}.freeze
    DEFAULT_NAMESPACE = 'default-namespace'.freeze
    DEFAULT_TASK_QUEUE = 'default-task-queue'.freeze
    DEFAULT_CONVERTER = Temporal::Client::Converter::Composite.new(
      converters: [
        Temporal::Client::Converter::Nil.new,
        Temporal::Client::Converter::Bytes.new,
        Temporal::Client::Converter::JSON.new,
        Temporal::Client::Converter::Legacy.new
      ]
    ).freeze

    def initialize
      @client_type = :grpc
      @logger = Logger.new(STDOUT, progname: 'temporal_client')
      @metrics_adapter = MetricsAdapters::Null.new
      @timeouts = DEFAULT_TIMEOUTS
      @namespace = DEFAULT_NAMESPACE
      @task_queue = DEFAULT_TASK_QUEUE
      @headers = DEFAULT_HEADERS
      @converter = DEFAULT_CONVERTER
      @error_handlers = []
    end

    def on_error(&block)
      @error_handlers << block
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

    def converter
      @converter
    end
  end
end
