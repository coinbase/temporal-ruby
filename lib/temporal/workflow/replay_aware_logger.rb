module Temporal
  class Workflow
    class ReplayAwareLogger
      SEVERITIES = %i[debug info warn error fatal unknown].freeze

      def initialize(main_logger, replaying:)
        @main_logger = main_logger
        @replaying = replaying
      end

      SEVERITIES.each do |severity|
        define_method severity do |message, data = {}|
          return if replay?

          main_logger.public_send(severity, message, data)
        end
      end

      def log(severity, message, data = {})
        return if replay?

        main_logger.log(severity, message, data)
      end

      private

      attr_reader :main_logger

      def replay?
        @replaying.call
      end
    end
  end
end
