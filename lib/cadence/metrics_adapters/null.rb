module Cadence
  module MetricsAdapters
    class Null
      def count(_key, _count, _tags); end
      def gauge(_key, _value, _tags); end
      def timing(_key, _time, _tags); end
    end
  end
end
