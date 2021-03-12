require 'temporal/client/grpc_client'

module Temporal
  module Client
    CLIENT_TYPES_MAP = {
      grpc: Temporal::Client::GRPCClient
    }.freeze

    def self.generate
      client_class = CLIENT_TYPES_MAP[Temporal.configuration.client_type]
      host = Temporal.configuration.host
      port = Temporal.configuration.port
      cert = Temporal.configuration.cert
      private_key = Temporal.configuration.private_key

      hostname = `hostname`
      thread_id = Thread.current.object_id
      identity = "#{thread_id}@#{hostname}"

      client_class.new(host, port, identity, cert, private_key)
    end
  end
end
