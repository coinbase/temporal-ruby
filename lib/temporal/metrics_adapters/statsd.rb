module Temporal
  module MetricsAdapter
    class Statsd
      def initialize(logger)
        @logger = logger
      end

      [:count, :gauge, :timing].each do |method_name|
        define_method(method_name) do |key, value, tags = {}|
          logger.public_send(method_name, key, value, tags: tags)
        end
      end
    end
  end
end
