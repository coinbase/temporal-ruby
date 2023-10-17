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
      identity = configuration.identity
      options = configuration.connection_options

      connection_class.new(host, port, identity, credentials, options)
    end
  end
end
