require 'securerandom'

module Cadence
  module Testing
    class LocalActivityContext
      attr_reader :idem

      def initialize
        @idem = SecureRandom.uuid
      end

      def logger
        Cadence.logger
      end

      def heartbeat(details = nil)
        raise NotImplementedError, 'not yet available for testing'
      end
    end
  end
end
