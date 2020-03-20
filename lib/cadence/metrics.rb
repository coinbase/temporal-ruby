module Cadence
  class Metrics
    def initialize(adapter)
      @adapter = adapter
    end

    def increment(key, tags = {})
      count(key, 1, tags)
    end

    def decrement(key, tags = {})
      count(key, -1, tags)
    end

    def count(key, count, tags = {})
      adapter.count(key, count, tags)
    rescue StandardError => error
      Cadence.logger.error("Adapter failed to send count metrics for #{key}: #{error.inspect}")
    end

    def gauge(key, value, tags = {})
      adapter.gauge(key, value, tags)
    rescue StandardError => error
      Cadence.logger.error("Adapter failed to send gauge metrics for #{key}: #{error.inspect}")
    end

    def timing(key, time, tags = {})
      adapter.timing(key, time, tags)
    rescue StandardError => error
      Cadence.logger.error("Adapter failed to send timing metrics for #{key}: #{error.inspect}")
    end

    private

    attr_reader :adapter
  end
end
