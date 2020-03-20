module Cadence
  module MetricsAdapters
    class Log
      def initialize(logger)
        @logger = logger
      end

      def count(key, count, tags)
        logger.debug(format_message(key, 'count', count, tags))
      end

      def gauge(key, value, tags)
        logger.debug(format_message(key, 'gauge', value, tags))
      end

      def timing(key, time, tags)
        logger.debug(format_message(key, 'timing', time, tags))
      end

      private

      attr_reader :logger

      def format_message(key, type, value, tags)
        tags_str = tags.map { |k, v| "#{k}:#{v}" }.join(',')
        parts = [key, type, value]
        parts << tags_str if !tags_str.empty?

        parts.join(' | ')
      end
    end
  end
end
