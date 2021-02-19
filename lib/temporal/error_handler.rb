module Temporal
  module ErrorHandler
    def self.handle(error, task: nil, metadata: nil)
      Temporal.configuration.error_handlers.each do |handler|
        handler.call(error, task: task, metadata: metadata.to_h)
      rescue StandardError => e
        binding.pry
        Temporal.logger.error("Error handler failed: #{e.inspect}")
      end
    end
  end
end
