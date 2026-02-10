module Temporal
  module Connection
    autoload :GRPC, 'temporal/connection/grpc'

    CLIENT_TYPES_MAP = {
      grpc: :GRPC
    }.freeze

    def self.generate(configuration)
      connection_class = const_get(CLIENT_TYPES_MAP.fetch(configuration.type))
      host = configuration.host
      port = configuration.port
      credentials = configuration.credentials
      identity = configuration.identity

      connection_class.new(host, port, identity, credentials)
    end
  end
end
