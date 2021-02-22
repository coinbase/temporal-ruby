module Temporal
  module ErrorHandler
    def self.handle(error, metadata: nil)
      Temporal.configuration.error_handlers.each do |handler|
        handler.call(error, metadata: metadata)
      rescue StandardError => e
        Temporal.logger.error("Error handler failed: #{e.inspect}")
      end
    end
  end
end
