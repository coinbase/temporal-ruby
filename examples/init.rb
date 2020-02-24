$LOAD_PATH.unshift __dir__

require 'bundler'
Bundler.require :default

require 'cadence'

Cadence.configure do |config|
  config.host = 'localhost'
  config.port = 6666
  config.domain = 'ruby-samples'
  config.task_list = 'general'
end
