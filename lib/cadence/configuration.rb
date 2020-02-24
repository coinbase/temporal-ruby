require 'logger'

module Cadence
  class Configuration
    attr_reader :timeouts
    attr_accessor :client_type, :host, :port, :logger, :domain, :task_list

    DEFAULT_TIMEOUTS = {
      execution: 60,         # End-to-end workflow time
      task: 10,              # Decision task processing time
      schedule_to_close: 40, # End-to-end activity time
      schedule_to_start: 10, # Queue time for an activity
      start_to_close: 30,    # Time spent processing an activity
      heartbeat: 30          # Max time between heartbeats
    }.freeze

    DEFAULT_DOMAIN = 'default-domain'.freeze
    DEFAULT_TASK_LIST = 'default-task-list'.freeze

    def initialize
      @client_type = :thrift
      @logger = Logger.new(STDOUT, progname: 'cadence_client')
      @timeouts = DEFAULT_TIMEOUTS
      @domain = DEFAULT_DOMAIN
      @task_list = DEFAULT_TASK_LIST
    end

    def timeouts=(new_timeouts)
      @timeouts = timeouts.merge(new_timeouts)
    end
  end
end
