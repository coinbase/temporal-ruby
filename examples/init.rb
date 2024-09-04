$LOAD_PATH.unshift __dir__

require 'bundler'
Bundler.require :default

require 'temporal'
require 'temporal/metrics_adapters/log'

metrics_logger = Logger.new(STDOUT, progname: 'metrics')

DEFAULT_NAMESPACE = 'ruby-samples'.freeze
DEFAULT_TASK_QUEUE = 'general'.freeze

Temporal.configure do |config|
  config.host = ENV.fetch('TEMPORAL_HOST', 'localhost')
  config.port = ENV.fetch('TEMPORAL_PORT', 7233).to_i
  config.namespace = ENV.fetch('TEMPORAL_NAMESPACE', DEFAULT_NAMESPACE)
  config.task_queue = ENV.fetch('TEMPORAL_TASK_QUEUE', DEFAULT_TASK_QUEUE)
  config.metrics_adapter = Temporal::MetricsAdapters::Log.new(metrics_logger)
end
