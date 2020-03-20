$LOAD_PATH.unshift __dir__

require 'bundler'
Bundler.require :default

require 'cadence'
require 'cadence/metrics_adapters/log'

metrics_logger = Logger.new(STDOUT, progname: 'metrics')

Cadence.configure do |config|
  config.host = 'localhost'
  config.port = 6666
  config.domain = 'ruby-samples'
  config.task_list = 'general'
  config.metrics_adapter = Cadence::MetricsAdapters::Log.new(metrics_logger)
end
