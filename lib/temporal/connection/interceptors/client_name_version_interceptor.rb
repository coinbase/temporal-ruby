require 'grpc'
require 'temporal/version'

module Temporal
  module Connection
    class ClientNameVersionInterceptor < GRPC::ClientInterceptor
      def request_response(request: nil, call: nil, method: nil, metadata: nil)
        metadata['client-name'] = 'community-ruby'
        metadata['client-version'] = Temporal::VERSION
        yield
      end
    end
  end
end
