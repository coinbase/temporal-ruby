require 'bundler'
Bundler.require :default

require 'temporal'

Temporal.configure do |config|
  config.host = 'localhost'
  config.port = 7233
  config.namespace = 'ruby-samples'
  config.task_queue = 'ui-driven'
end

begin
  Temporal.register_namespace('ruby-samples', 'A safe space for playing with Temporal Ruby')
rescue Temporal::NamespaceAlreadyExistsFailure
  nil # service was already registered
end
