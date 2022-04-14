require 'temporal/connection/grpc'

module Temporal
  module Connection
    CLIENT_TYPES_MAP = {
      grpc: Temporal::Connection::GRPC
    }.freeze

    def self.generate(configuration)
      connection_class = CLIENT_TYPES_MAP[configuration.type]
      host = configuration.host
      port = configuration.port
      options = configuration.options

      hostname = `hostname`
      thread_id = Thread.current.object_id
      identity = "#{thread_id}@#{hostname}"

      connection_class.new(host, port, identity, options)
    end
  end
end
