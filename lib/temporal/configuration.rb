require 'temporal/capabilities'
require 'temporal/logger'
require 'temporal/metrics_adapters/null'
require 'temporal/middleware/header_propagator_chain'
require 'temporal/middleware/entry'
require 'temporal/connection/converter/payload/nil'
require 'temporal/connection/converter/payload/bytes'
require 'temporal/connection/converter/payload/json'
require 'temporal/connection/converter/payload/proto_json'
require 'temporal/connection/converter/composite'
require 'temporal/connection/converter/codec/chain'

module Temporal
  class Configuration
    # NOTE: https://github.com/grpc/grpc/blob/a04188b29f6f3165e54cff9e9586ab570421a6b0/src/ruby/lib/grpc/generic/client_stub.rb#L98
    GRPCConfig = Struct.new(:channel_override, :timeout, :propagate_mask, :channel_args, :interceptors, keyword_init: true) do |new_class|
      def to_hash
        {
          channel_override: channel_override,
          timeout: timeout,
          propagate_mask: propagate_mask,
          channel_args: channel_args,
          interceptors: interceptors
        }.compact
      end
    end
    CONNECTION_TYPES_MAP = {
      :grpc => GRPCConfig
    }
    Connection = Struct.new(:type, :host, :port, :credentials, :identity, :client_config, keyword_init: true)
    Execution = Struct.new(:namespace, :task_queue, :timeouts, :headers, :search_attributes, keyword_init: true)

    attr_reader :timeouts, :error_handlers, :capabilities
    attr_accessor :connection_type, :client_config, :payload_converters_options, :converter, :use_error_serialization_v2, :host, :port, :credentials, :identity,
                  :logger, :metrics_adapter, :namespace, :task_queue, :headers, :search_attributes, :header_propagators,
                  :payload_codec, :legacy_signals, :no_signals_in_first_task

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
      heartbeat: nil,         # Max time between heartbeats (off by default)
      # If a heartbeat timeout is specified, 80% of that value will be used for throttling. If not specified, this
      # value will be used. This default comes from the Go SDK.
      # https://github.com/temporalio/sdk-go/blob/eaa3802876de77500164f80f378559c51d6bb0e2/internal/internal_task_handlers.go#L65
      default_heartbeat_throttle_interval: 30,
      # Heartbeat throttling interval will always be capped by this value. This default comes from the Go SDK.
      # https://github.com/temporalio/sdk-go/blob/eaa3802876de77500164f80f378559c51d6bb0e2/internal/internal_task_handlers.go#L66
      #
      # To disable heartbeat throttling, set this timeout to 0.
      max_heartbeat_throttle_interval: 60
    }.freeze

    DEFAULT_HEADERS = {}.freeze
    DEFAULT_NAMESPACE = 'default-namespace'.freeze
    DEFAULT_TASK_QUEUE = 'default-task-queue'.freeze
    DEFAULT_PAYLOAD_CONVERTER_KLASSES = [
      Temporal::Connection::Converter::Payload::Nil,
      Temporal::Connection::Converter::Payload::Bytes,
      Temporal::Connection::Converter::Payload::ProtoJSON,
      Temporal::Connection::Converter::Payload::JSON
    ].freeze
    DEFAULT_CONVERTER_KLASS = Temporal::Connection::Converter::Composite

    # The Payload Codec is an optional step that happens between the wire and the Payload Converter:
    # Temporal Server <--> Wire <--> Payload Codec <--> Payload Converter <--> User code
    # which can be useful for transformations such as compression and encryption
    # more info at https://docs.temporal.io/security#payload-codec
    DEFAULT_PAYLOAD_CODEC = Temporal::Connection::Converter::Codec::Chain.new(
      payload_codecs: []
    ).freeze

    def initialize
      @connection_type = :grpc
      @client_config = {}
      @payload_converters_options = {}
      @logger = Temporal::Logger.new(STDOUT, progname: 'temporal_client')
      @metrics_adapter = MetricsAdapters::Null.new
      @timeouts = DEFAULT_TIMEOUTS
      @namespace = DEFAULT_NAMESPACE
      @task_queue = DEFAULT_TASK_QUEUE
      @headers = DEFAULT_HEADERS
      @payload_codec = DEFAULT_PAYLOAD_CODEC
      @use_error_serialization_v2 = false
      @error_handlers = []
      @credentials = :this_channel_is_insecure
      @identity = nil
      @search_attributes = {}
      @header_propagators = []
      @capabilities = Capabilities.new(self)
      # Signals previously were incorrectly replayed in order within a workflow task window, rather
      # than at the beginning. Correcting this changes the determinism of any workflow with signals.
      # This flag exists to force this legacy behavior to gradually roll out the new ordering.
      # Because this feature depends on the SDK Metadata capability which only became available
      # in Temporal server 1.20, it is ignored when connected to older versions and effectively
      # treated as true.
      @legacy_signals = false

      # This is a legacy behavior that is incorrect, but which existing workflow code may rely on. Only
      # set to true until you can fix your workflow code.
      @no_signals_in_first_task = false
    end

    def converter
      @converter ||= DEFAULT_CONVERTER_KLASS.new(
          payload_converters: DEFAULT_PAYLOAD_CONVERTER_KLASSES.map do |payload_converter_klass|
            payload_converter_klass.new(
              payload_converters_options.fetch(
                payload_converter_klass::ENCODING,
                {}
              )
            )
          end
        )
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
      client_config_class = CONNECTION_TYPES_MAP[connection_type]
      Connection.new(
        type: connection_type,
        host: host,
        port: port,
        credentials: credentials,
        identity: identity || default_identity,
        client_config: client_config_class.new(**client_config)
      ).freeze
    rescue ArgumentError
      # NOTE: `grpc` is the only supported connection type for now
      # https://github.com/Kaligo/temporal-ruby/blob/0c89d4ea55055fff7b9e8d13a5a962790649ac73/lib/temporal/connection.rb#L5
      raise 'Invalid configurations for `grpc` connection type'
    end

    def default_execution_options
      Execution.new(
        namespace: namespace,
        task_queue: task_list,
        timeouts: timeouts,
        headers: headers,
        search_attributes: search_attributes
      ).freeze
    end

    def add_header_propagator(propagator_class, *args)
      raise 'header propagator must implement `def inject!(headers)`' unless propagator_class.method_defined? :inject!

      @header_propagators << Middleware::Entry.new(propagator_class, args)
    end

    def header_propagator_chain
      Middleware::HeaderPropagatorChain.new(header_propagators)
    end

    private

    def default_identity
      hostname = `hostname`
      pid = Process.pid

      "#{pid}@#{hostname}".freeze
    end
  end
end
