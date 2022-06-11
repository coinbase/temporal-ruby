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
      credentials = configuration.credentials
      interceptors = configuration.interceptors

      hostname = `hostname`
      thread_id = Thread.current.object_id
      identity = "#{thread_id}@#{hostname}"

      connection_class.new(host, port, identity, credentials, interceptors)
    end
  end
end
