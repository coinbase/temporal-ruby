require 'temporal/logger'
require 'temporal/metrics_adapters/null'
require 'temporal/connection/converter/payload/nil'
require 'temporal/connection/converter/payload/bytes'
require 'temporal/connection/converter/payload/json'
require 'temporal/connection/converter/payload/proto_json'
require 'temporal/connection/converter/composite'

module Temporal
  class Configuration
    Connection = Struct.new(:type, :host, :port, :credentials, :identity, keyword_init: true)
    Execution = Struct.new(:namespace, :task_queue, :timeouts, :headers, :search_attributes, :workflow_id_reuse_policy, keyword_init: true)

    attr_reader :timeouts, :error_handlers
    attr_accessor :connection_type, :converter, :host, :port, :credentials, :identity, :logger, :metrics_adapter, :namespace, :task_queue, :headers, :search_attributes, :workflow_id_reuse_policy

    # See https://docs.temporal.io/blog/activity-timeouts/ for general docs.
    # We want an infinite execution timeout for cron schedules and other perpetual workflows.
    # We choose an 10-year execution timeout because that's the maximum the cassandra DB supports,
    # matching the go SDK, see https://github.com/temporalio/sdk-go/blob/d96130dad3d2bc189bc7626543bd5911cc07ff6d/internal/internal_workflow_testsuite.go#L68
    DEFAULT_TIMEOUTS = {
      execution: 86_400 * 365 * 10, # End-to-end workflow time, including all recurrences if it's scheduled.
      # Time for a single run, excluding retries.  Server defaults to execution timeout; we default here as well to be explicit.
      run: 86_400 * 365 * 10,
      # Workflow task processing time.  Workflows should not use the network and should execute very quickly.
      task: 10,
      schedule_to_close: nil, # End-to-end activity time (default: schedule_to_start + start_to_close)
      # Max queue time for an activity. Default: none.  This is dangerous; most teams don't use.
      # See       # https://docs.temporal.io/blog/activity-timeouts/#schedule-to-start-timeout
      schedule_to_start: nil,
      start_to_close: 30,     # Time spent processing an activity
      heartbeat: nil          # Max time between heartbeats (off by default)
    }.freeze

    DEFAULT_HEADERS = {}.freeze
    DEFAULT_NAMESPACE = 'default-namespace'.freeze
    DEFAULT_TASK_QUEUE = 'default-task-queue'.freeze
    DEFAULT_CONVERTER = Temporal::Connection::Converter::Composite.new(
      payload_converters: [
        Temporal::Connection::Converter::Payload::Nil.new,
        Temporal::Connection::Converter::Payload::Bytes.new,
        Temporal::Connection::Converter::Payload::ProtoJSON.new,
        Temporal::Connection::Converter::Payload::JSON.new
      ]
    ).freeze
    # default workflow id reuse policy is nil for backwards compatibility. in reality, the
    # default is :allow, due to that being the temporal server's default
    DEFAULT_WORKFLOW_ID_REUSE_POLICY = nil

    def initialize
      @connection_type = :grpc
      @logger = Temporal::Logger.new(STDOUT, progname: 'temporal_client')
      @metrics_adapter = MetricsAdapters::Null.new
      @timeouts = DEFAULT_TIMEOUTS
      @namespace = DEFAULT_NAMESPACE
      @task_queue = DEFAULT_TASK_QUEUE
      @headers = DEFAULT_HEADERS
      @converter = DEFAULT_CONVERTER
      @error_handlers = []
      @credentials = :this_channel_is_insecure
      @identity = nil
      @search_attributes = {}
      @workflow_id_reuse_policy = DEFAULT_WORKFLOW_ID_REUSE_POLICY
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

    def for_connection
      Connection.new(
        type: connection_type,
        host: host,
        port: port,
        credentials: credentials,
        identity: identity || default_identity
      ).freeze
    end

    def default_execution_options
      Execution.new(
        namespace: namespace,
        task_queue: task_list,
        timeouts: timeouts,
        headers: headers,
        search_attributes: search_attributes,
        workflow_id_reuse_policy: workflow_id_reuse_policy
      ).freeze
    end

    private

    def default_identity
      hostname = `hostname`
      pid = Process.pid

      "#{pid}@#{hostname}".freeze
    end
  end
end
