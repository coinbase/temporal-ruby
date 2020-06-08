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

      hostname = `hostname`
      thread_id = Thread.current.object_id
      identity = "#{thread_id}@#{hostname}"

      client_class.new(host, port, identity)
    end
  end
end
