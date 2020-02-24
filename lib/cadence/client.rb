require 'cadence/client/thrift_client'

module Cadence
  module Client
    CLIENT_TYPES_MAP = {
      thrift: Cadence::Client::ThriftClient
    }.freeze

    def self.generate
      client_class = CLIENT_TYPES_MAP[Cadence.configuration.client_type]
      host = Cadence.configuration.host
      port = Cadence.configuration.port

      hostname = `hostname`
      thread_id = Thread.current.object_id
      identity = "#{thread_id}@#{hostname}"

      client_class.new(host, port, identity)
    end
  end
end
