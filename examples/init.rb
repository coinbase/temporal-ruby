$LOAD_PATH.unshift __dir__

require 'bundler'
Bundler.require :default

require 'temporal'
require 'temporal/metrics_adapters/log'

metrics_logger = Logger.new(STDOUT, progname: 'metrics')

Temporal.configure do |config|
  config.host = 'localhost'
  config.port = 7233
  config.namespace = 'ruby-samples'
  config.task_list = 'general'
  config.metrics_adapter = Temporal::MetricsAdapters::Log.new(metrics_logger)
end
