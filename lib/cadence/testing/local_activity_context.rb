module Cadence
  module Testing
    class LocalActivityContext
      def logger
        Cadence.logger
      end

      def heartbeat(details = nil)
        raise NotImplementedError, 'not yet available for testing'
      end
    end
  end
end
